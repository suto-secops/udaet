#include "diarystore.h"

#include <QDate>
#include <QDir>
#include <QStandardPaths>
#include <QSqlDatabase>
#include <QSqlError>
#include <QSqlQuery>
#include <QStringList>
#include <QVariant>

namespace
{
constexpr int CurrentSchemaVersion = 1;
}

DiaryStore::DiaryStore(QObject *parent)
    : QObject(parent)
    , m_connectionName(QStringLiteral("udaet-primary"))
{
    m_currentDate = QDate::currentDate().toString(Qt::ISODate);
    if (openDatabase() && migrate()) {
        loadToday();
    }
}

QString DiaryStore::currentDate() const
{
    return m_currentDate;
}

QString DiaryStore::entryText() const
{
    return m_entryText;
}

double DiaryStore::rating() const
{
    return m_rating;
}

QString DiaryStore::ratingText() const
{
    return m_rated ? QString::number(m_rating, 'f', 2) : QString();
}

bool DiaryStore::rated() const
{
    return m_rated;
}

QString DiaryStore::errorMessage() const
{
    return m_errorMessage;
}

void DiaryStore::setEntryText(const QString &text)
{
    if (m_entryText == text) {
        return;
    }
    m_entryText = text;
    emit entryTextChanged();
}

void DiaryStore::setRating(double rating)
{
    if (rating < 0.0 || rating > 10.0) {
        return;
    }
    if (qFuzzyCompare(m_rating, rating) && m_rated) {
        return;
    }
    m_rating = rating;
    m_rated = true;
    emit ratingChanged();
    emit ratedChanged();
}

bool DiaryStore::saveCurrentDay()
{
    QSqlDatabase database = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(database);
    query.prepare(QStringLiteral(
        "INSERT INTO days (day, rating) VALUES (:day, :rating) "
        "ON CONFLICT(day) DO UPDATE SET rating = excluded.rating"));
    query.bindValue(QStringLiteral(":day"), m_currentDate);
    query.bindValue(QStringLiteral(":rating"), m_rated ? QVariant(m_rating) : QVariant());
    if (!query.exec()) {
        return setError(query.lastError().text());
    }

    query.prepare(QStringLiteral(
        "INSERT INTO entries (day, markdown) VALUES (:day, :markdown) "
        "ON CONFLICT(day) DO UPDATE SET markdown = excluded.markdown"));
    query.bindValue(QStringLiteral(":day"), m_currentDate);
    query.bindValue(QStringLiteral(":markdown"), m_entryText);
    if (!query.exec()) {
        return setError(query.lastError().text());
    }
    clearError();
    return true;
}

bool DiaryStore::loadDay(const QString &date)
{
    const QDate parsedDate = QDate::fromString(date, Qt::ISODate);
    if (!parsedDate.isValid()) {
        return setError(QStringLiteral("The selected date is invalid."));
    }

    QSqlDatabase database = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(database);
    query.prepare(QStringLiteral(
        "SELECT d.rating, e.markdown FROM days d "
        "LEFT JOIN entries e ON e.day = d.day WHERE d.day = :day"));
    query.bindValue(QStringLiteral(":day"), date);
    if (!query.exec()) {
        return setError(query.lastError().text());
    }

    const QString oldDate = m_currentDate;
    const QString oldText = m_entryText;
    const double oldRating = m_rating;
    const bool oldRated = m_rated;
    m_currentDate = date;
    m_entryText.clear();
    m_rating = 0.0;
    m_rated = false;
    if (query.next()) {
        m_rated = !query.value(0).isNull();
        if (m_rated) {
            m_rating = query.value(0).toDouble();
        }
        m_entryText = query.value(1).toString();
    }

    if (oldDate != m_currentDate) {
        emit currentDateChanged();
    }
    if (oldText != m_entryText) {
        emit entryTextChanged();
    }
    if (!qFuzzyCompare(oldRating, m_rating) || oldRated != m_rated) {
        emit ratingChanged();
    }
    if (oldRated != m_rated) {
        emit ratedChanged();
    }
    clearError();
    return true;
}

void DiaryStore::loadToday()
{
    loadDay(QDate::currentDate().toString(Qt::ISODate));
}

void DiaryStore::clearRating()
{
    if (!m_rated) {
        return;
    }
    m_rating = 0.0;
    m_rated = false;
    emit ratingChanged();
    emit ratedChanged();
}

bool DiaryStore::setRatingText(const QString &text)
{
    const QString trimmed = text.trimmed();
    if (trimmed.isEmpty()) {
        clearRating();
        return true;
    }

    bool valid = false;
    const double parsedRating = trimmed.toDouble(&valid);
    if (!valid || parsedRating < 0.0 || parsedRating > 10.0
        || (trimmed.contains('.') && trimmed.section('.', 1).size() > 2)) {
        return false;
    }
    setRating(parsedRating);
    return true;
}

bool DiaryStore::openDatabase()
{
    const QString dataDirectory =
        QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    if (!QDir().mkpath(dataDirectory)) {
        return setError(QStringLiteral("Unable to create the application data directory."));
    }

    QSqlDatabase database = QSqlDatabase::addDatabase(
        QStringLiteral("QSQLITE"), m_connectionName);
    database.setDatabaseName(QDir(dataDirectory).filePath(QStringLiteral("udaet.sqlite")));
    if (!database.open()) {
        return setError(database.lastError().text());
    }
    return true;
}

bool DiaryStore::migrate()
{
    QSqlDatabase database = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(database);
    if (!query.exec(QStringLiteral("PRAGMA foreign_keys = ON"))) {
        return setError(query.lastError().text());
    }
    if (!query.exec(QStringLiteral(
            "CREATE TABLE IF NOT EXISTS schema_version "
            "(version INTEGER NOT NULL)"))) {
        return setError(query.lastError().text());
    }

    if (!query.exec(QStringLiteral("SELECT version FROM schema_version LIMIT 1"))) {
        return setError(query.lastError().text());
    }
    const int version = query.next() ? query.value(0).toInt() : 0;
    if (version > CurrentSchemaVersion) {
        return setError(QStringLiteral("The diary database is newer than this application."));
    }
    if (version == CurrentSchemaVersion) {
        return true;
    }

    if (!database.transaction()) {
        return setError(database.lastError().text());
    }
    const QStringList statements{
        QStringLiteral(
            "CREATE TABLE IF NOT EXISTS days ("
            "day TEXT PRIMARY KEY, rating REAL CHECK (rating IS NULL OR (rating >= 0 AND rating <= 10)))"),
        QStringLiteral(
            "CREATE TABLE IF NOT EXISTS entries ("
            "day TEXT PRIMARY KEY REFERENCES days(day) ON DELETE CASCADE, markdown TEXT NOT NULL DEFAULT '')"),
        QStringLiteral(
            "CREATE TABLE IF NOT EXISTS attachments ("
            "id TEXT PRIMARY KEY, day TEXT NOT NULL REFERENCES days(day) ON DELETE CASCADE, "
            "path TEXT NOT NULL, mime_type TEXT NOT NULL, sort_order INTEGER NOT NULL DEFAULT 0)"),
        QStringLiteral(
            "CREATE TABLE IF NOT EXISTS metrics ("
            "day TEXT NOT NULL REFERENCES days(day) ON DELETE CASCADE, "
            "name TEXT NOT NULL, value REAL NOT NULL, PRIMARY KEY(day, name))"),
        QStringLiteral("DELETE FROM schema_version"),
        QStringLiteral("INSERT INTO schema_version(version) VALUES (1)")};
    for (const QString &statement : statements) {
        if (!query.exec(statement)) {
            database.rollback();
            return setError(query.lastError().text());
        }
    }
    if (!database.commit()) {
        return setError(database.lastError().text());
    }
    return true;
}

bool DiaryStore::setError(const QString &message)
{
    m_errorMessage = message;
    emit errorMessageChanged();
    return false;
}

void DiaryStore::clearError()
{
    if (m_errorMessage.isEmpty()) {
        return;
    }
    m_errorMessage.clear();
    emit errorMessageChanged();
}
