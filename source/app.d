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

            if(!o.meteo.t.isNull) meteo ~= Measurement("t_", "deg", o.meteo.t.get);
            if(!o.meteo.ws.isNull) meteo ~= Measurement("ws_", "м/с", o.meteo.ws.get);
            if(!o.meteo.wd.isNull) meteo ~= Measurement("wd_", "deg", o.meteo.wd.get);
            if(!o.meteo.hum.isNull) meteo ~= Measurement("hum_", "%", o.meteo.hum.get);
            if(!o.meteo.p.isNull) meteo ~= Measurement("p_", "мм.рт.ст.", o.meteo.p.get);

            const meteoTime = measurementsOfObservatory.maxElement!((a) => a.dateTime).dateTime;

            foreach(ref m; meteo)
                m.dateTime = meteoTime;

            measurementsOfObservatory ~= meteo;
        }

        dbClient.upsertMeasurementsToDB(currTime, o.coords, o.name, measurementsOfObservatory);
    }
}
