import krasecodump.grab;
import krasecodump.pgdb;
import std.stdio;
import std.datetime;
import vibe.db.postgresql;

void main(string[] args)
{
    const postgresConnString = args[1];
    auto dbClient = new PostgresClient(postgresConnString, 5);

    auto obs = requestObservatories;
    const currTime = Clock.currTime;

    foreach(const ref o; obs)
    {
        auto measurementsOfObservatory = o.obsId.requestKrasecoData;

        // Добавляем метеоданные отдельно потому что они не отдаются в виде истории измерений
        if(measurementsOfObservatory.length)
        {
            import std.algorithm.searching: maxElement;

            Measurement[] meteo;

            const dbrd = " (dashboard)";

            if(!o.meteo.t.isNull) meteo ~= Measurement("Температура воздуха"~dbrd, "deg", o.meteo.t.get);
            if(!o.meteo.ws.isNull) meteo ~= Measurement("Скорость ветра"~dbrd, "м/с", o.meteo.ws.get);
            if(!o.meteo.wd.isNull) meteo ~= Measurement("Направление ветра"~dbrd, "deg", o.meteo.wd.get);
            if(!o.meteo.hum.isNull) meteo ~= Measurement("Влажность воздуха"~dbrd, "%", o.meteo.hum.get);
            if(!o.meteo.p.isNull) meteo ~= Measurement("Атм. давление"~dbrd, "мм.рт.ст.", o.meteo.p.get);

            const meteoTime = measurementsOfObservatory.maxElement!((a) => a.dateTime).dateTime;

            foreach(ref m; meteo)
                m.dateTime = meteoTime;

            measurementsOfObservatory ~= meteo;
        }

        dbClient.upsertMeasurementsToDB(currTime, o.coords, o.name, measurementsOfObservatory);
    }
}
