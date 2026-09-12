#include "diarystore.h"

#include <QDate>
#include <QDir>
#include <QStandardPaths>
#include <QSqlDatabase>
#include <QSqlError>
#include <QSqlQuery>
#include <QSettings>
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
    QSettings settings;
    m_dateOrder = settings.value(QStringLiteral("dateOrder"), m_dateOrder).toString();
    m_dateSeparator = settings.value(QStringLiteral("dateSeparator"), m_dateSeparator).toString();
    m_currentDate = QDate::currentDate().toString(Qt::ISODate);
    if (openDatabase() && migrate()) {
        loadToday();
    }
}

QString DiaryStore::currentDate() const
{
    return formatDate(m_currentDate);
}

QString DiaryStore::dateOrder() const
{
    return m_dateOrder;
}

QString DiaryStore::dateSeparator() const
{
    return m_dateSeparator;
}

QString DiaryStore::entryText() const
{
    return m_entryText;
}

int DiaryStore::hardBreakCount() const
{
    int count = 0;
    const QStringList lines = m_entryText.split(QLatin1Char('\n'));
    for (const QString &line : lines) {
        int trailingSpaces = 0;
        for (qsizetype index = line.size() - 1; index >= 0
             && line.at(index) == QLatin1Char(' '); --index) {
            ++trailingSpaces;
        }
        if (trailingSpaces >= 2) {
            ++count;
        }
    }
    return count;
}

QString DiaryStore::hardBreakGuide() const
{
    QStringList markers;
    const QStringList lines = m_entryText.split(QLatin1Char('\n'));
    for (const QString &line : lines) {
        int trailingSpaces = 0;
        for (qsizetype index = line.size() - 1; index >= 0
             && line.at(index) == QLatin1Char(' '); --index) {
            ++trailingSpaces;
        }
        if (trailingSpaces >= 2) {
            markers.append(QStringLiteral("·").repeated(trailingSpaces) + QStringLiteral(" ↵"));
        }
    }
    return markers.join(QStringLiteral("   "));
}

double DiaryStore::rating() const
{
    return m_rating;
}

QString DiaryStore::ratingText() const
{
    if (!m_rated) {
        return {};
    }
    QString value = QString::number(m_rating, 'f', 2);
    while (value.endsWith(QLatin1Char('0'))) {
        value.chop(1);
    }
    if (value.endsWith(QLatin1Char('.'))) {
        value.chop(1);
    }
    return value;
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

void DiaryStore::setDateOrder(const QString &order)
{
    if (order != QStringLiteral("dd MM yyyy")
        && order != QStringLiteral("MM dd yyyy")
        && order != QStringLiteral("yyyy MM dd")) {
        return;
    }
    if (m_dateOrder == order) {
        return;
    }
    m_dateOrder = order;
    QSettings().setValue(QStringLiteral("dateOrder"), m_dateOrder);
    emit dateFormatChanged();
    emit currentDateChanged();
}

void DiaryStore::setDateSeparator(const QString &separator)
{
    if (separator != QStringLiteral("-") && separator != QStringLiteral("/")) {
        return;
    }
    if (m_dateSeparator == separator) {
        return;
    }
    m_dateSeparator = separator;
    QSettings().setValue(QStringLiteral("dateSeparator"), m_dateSeparator);
    emit dateFormatChanged();
    emit currentDateChanged();
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
    const QDate parsedDate = parseDate(date);
    if (!parsedDate.isValid()) {
        return setError(QStringLiteral("The selected date is invalid."));
    }
    const QString normalizedDate = parsedDate.toString(Qt::ISODate);

    QSqlDatabase database = QSqlDatabase::database(m_connectionName);
    QSqlQuery query(database);
    query.prepare(QStringLiteral(
        "SELECT d.rating, e.markdown FROM days d "
        "LEFT JOIN entries e ON e.day = d.day WHERE d.day = :day"));
    query.bindValue(QStringLiteral(":day"), normalizedDate);
    if (!query.exec()) {
        return setError(query.lastError().text());
    }

    const QString oldDate = m_currentDate;
    const QString oldText = m_entryText;
    const double oldRating = m_rating;
    const bool oldRated = m_rated;
    m_currentDate = normalizedDate;
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

QString DiaryStore::formatDate(const QString &isoDate) const
{
    const QDate date = QDate::fromString(isoDate, Qt::ISODate);
    if (!date.isValid()) {
        return isoDate;
    }
    QString formatted = m_dateOrder;
    formatted.replace(QStringLiteral(" "), m_dateSeparator);
    return date.toString(formatted);
}

QDate DiaryStore::parseDate(const QString &date) const
{
    const QString trimmed = date.trimmed();
    const QDate isoDate = QDate::fromString(trimmed, Qt::ISODate);
    if (isoDate.isValid()) {
        return isoDate;
    }
    QString pattern = m_dateOrder;
    pattern.replace(QStringLiteral(" "), m_dateSeparator);
    return QDate::fromString(trimmed, pattern);
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

QVariantList DiaryStore::daysWithContent(int year, int month) const
{
    QVariantList days;
    const QDate monthStart(year, month, 1);
    if (!monthStart.isValid()) {
        return days;
    }

    QSqlQuery query(QSqlDatabase::database(m_connectionName));
    query.prepare(QStringLiteral(
        "SELECT day FROM days WHERE day >= :start AND day < :end ORDER BY day"));
    query.bindValue(QStringLiteral(":start"), monthStart.toString(Qt::ISODate));
    query.bindValue(QStringLiteral(":end"), monthStart.addMonths(1).toString(Qt::ISODate));
    if (!query.exec()) {
        return days;
    }
    while (query.next()) {
        days.append(query.value(0).toString());
    }
    return days;
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
