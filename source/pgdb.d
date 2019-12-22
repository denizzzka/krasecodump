module krasecodump.pgdb;

import krasecodump.grab;
import vibe.db.postgresql;
import db.util;

short upsertPlace(Connection conn, Coords coords)
{
    auto qp = statementWrapper(
        `INSERT INTO places (`,
            i("lat", coords.lat),
            i("lon", coords.lon),
        `) VALUES(`, Dollars(), `) `~
        `ON CONFLICT (lat, lon) `~
        `DO NOTHING `~
        `RETURNING id`
    );

    auto r = conn.execStatement(qp);
    r.checkOneRowResult;

    return r[0][0].as!short;
}

void upsertMeasurement(Connection conn, short placeId, Measurement measurement)
{
    auto qp = statementWrapper(
        `INSERT INTO measurements (`,
            i("place_id", placeId),
            i("time", measurement.dateTime),
            i("substance_name", measurement.name),
            i("value", measurement.value),
            i("pdk", measurement.pdk),
            i("unit", measurement.unit),
        `) VALUES(`, Dollars(), `) `~
        `ON CONFLICT (place_id, time, substance_name, value, pdk, unit) `~
        `DO NOTHING`
    );

    conn.execStatement(qp);
}
