module krasecodump.pgdb;

import krasecodump.grab;
import vibe.db.postgresql;
import db.util;
import std.conv: to;
import std.typecons: Nullable;

private int upsertPlace(Connection conn, Coords coords, string name)
{
    auto qp = statementWrapper(
        `INSERT INTO places (`,
            i("lat", coords.lat),
            i("lon", coords.lon),
            i("name", name),
        `) VALUES(`, Dollars(), `) `~
        `ON CONFLICT (lat, lon) `~
        `DO UPDATE SET lat = EXCLUDED.lat `~ // just for ensure what RETURNING always returns value
        `RETURNING id`
    );

    auto r = conn.execStatement(qp);
    r.checkOneRowResult;

    return r[0][0].as!int;
}

private int upsertSubstance(Connection conn, string name, string unit, Nullable!double pdk)
{
    auto qp = statementWrapper(
        `INSERT INTO substances (`,
            i("substance_name", name),
            i("unit", unit),
            i("pdk", pdk),
        `) VALUES(`, Dollars(), `) `~
        `ON CONFLICT (substance_name, unit, pdk) `~
        `DO UPDATE SET pdk = EXCLUDED.pdk `~ // just for ensure what RETURNING always returns value
        `RETURNING id`
    );

    auto r = conn.execStatement(qp);
    r.checkOneRowResult;

    return r[0][0].as!int;
}

private void upsertMeasurement(Connection conn, short placeId, in Measurement m)
{
    const substanceId = conn.upsertSubstance(m.name, m.unit, m.pdk);

    auto qp = statementWrapper(
        `INSERT INTO measurements (`,
            i("place_id", placeId),
            i("time", m.dateTime),
            i("substance_id", substanceId),
            i("value", m.value),
        `) VALUES(`, Dollars(), `) `~
        `ON CONFLICT (place_id, time, substance_id, value) `~
        `DO NOTHING`
    );

    conn.execStatement(qp);
}

void upsertMeasurementsToDB(PostgresClient client, in Coords coords, string observatoryName, in Measurement[] measurements)
{
    client.pickConnection(
        (scope conn)
        {
            // для скорости транзакций, сохранность данных нам не особо важна здесь
            conn.execStatement("SET synchronous_commit TO OFF");

            const placeId = conn.upsertPlace(coords, observatoryName).to!short;

            foreach(const ref m; measurements)
                conn.upsertMeasurement(placeId, m);
        }
    );
}
