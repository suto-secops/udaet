#pragma once

#include <QObject>
#include <QString>
#include <QVariantList>

class DiaryStore final : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString currentDate READ currentDate NOTIFY currentDateChanged)
    Q_PROPERTY(QString entryText READ entryText WRITE setEntryText NOTIFY entryTextChanged)
    Q_PROPERTY(int hardBreakCount READ hardBreakCount NOTIFY entryTextChanged)
    Q_PROPERTY(QString hardBreakGuide READ hardBreakGuide NOTIFY entryTextChanged)
    Q_PROPERTY(double rating READ rating WRITE setRating NOTIFY ratingChanged)
    Q_PROPERTY(QString ratingText READ ratingText NOTIFY ratingChanged)
    Q_PROPERTY(bool rated READ rated NOTIFY ratedChanged)
    Q_PROPERTY(QString errorMessage READ errorMessage NOTIFY errorMessageChanged)

public:
    explicit DiaryStore(QObject *parent = nullptr);

    QString currentDate() const;
    QString entryText() const;
    int hardBreakCount() const;
    QString hardBreakGuide() const;
    double rating() const;
    QString ratingText() const;
    bool rated() const;
    QString errorMessage() const;

    void setEntryText(const QString &text);
    void setRating(double rating);

    Q_INVOKABLE bool saveCurrentDay();
    Q_INVOKABLE bool loadDay(const QString &date);
    Q_INVOKABLE void loadToday();
    Q_INVOKABLE void clearRating();
    Q_INVOKABLE bool setRatingText(const QString &text);
    Q_INVOKABLE QVariantList daysWithContent(int year, int month) const;

signals:
    void currentDateChanged();
    void entryTextChanged();
    void ratingChanged();
    void ratedChanged();
    void errorMessageChanged();

private:
    bool openDatabase();
    bool migrate();
    bool setError(const QString &message);
    void clearError();

    QString m_currentDate;
    QString m_entryText;
    double m_rating = 0.0;
    bool m_rated = false;
    QString m_errorMessage;
    QString m_connectionName;
};
