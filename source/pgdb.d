module krasecodump.pgdb;

import krasecodump.grab;
import vibe.db.postgresql;
import dpq2.query_gen;
import std.conv: to;
import std.datetime: SysTime;
import std.exception: enforce;
import std.typecons: Nullable;

private Nullable!int selectPlace(Connection conn, Coords coords, string name)
{
    auto qp = wrapStatement(
        `SELECT place_id`,
        `FROM places`,
        `WHERE`, u("lat", coords.lat),
        `AND`, u("lon", coords.lon),
        `LIMIT 1`
    );

    auto r = conn.execStatement(qp);
    enforce(r.length <= 1);

    Nullable!int ret;

    if(r.length == 1)
        ret = r[0][0].as!int;

    return ret;
}

private int upsertPlace(Connection conn, Coords coords, string name)
{
    auto selected = conn.selectPlace(coords, name);

    if(!selected.isNull)
        return selected.get;
    else
        return conn.upsertPlaceHurtsSequence(coords, name);
}

// При каждом вызове вызывает приращение sequence
private int upsertPlaceHurtsSequence(Connection conn, Coords coords, string name)
{
    auto qp = wrapStatement(
        `INSERT INTO places (`,
            i("lat", coords.lat),
            i("lon", coords.lon),
            i("place_name", name),
        `) VALUES(`, Dollars(), `)`,
        `ON CONFLICT (lat, lon)`,
        `DO UPDATE SET lat = EXCLUDED.lat`, // just for ensure what RETURNING always returns value
        `RETURNING place_id`
    );

    auto r = conn.execStatement(qp);
    r.checkOneRowResult;

    return r[0][0].as!int;
}

private Nullable!int selectSubstance(Connection conn, string name, string unit, double pdk)
{
    auto qp = wrapStatement(
        `SELECT substance_id`,
        `FROM substances`,
        `WHERE`, u("substance_name", name),
        `AND`, u("unit", unit),
        `AND`, u("pdk", pdk),
        `LIMIT 1`
    );

    auto r = conn.execStatement(qp);
    enforce(r.length <= 1);

    Nullable!int ret;

    if(r.length == 1)
        ret = r[0][0].as!int;

    return ret;
}

private int upsertSubstance(Connection conn, string name, string unit, double pdk)
{
    auto selected = conn.selectSubstance(name, unit, pdk);

    if(!selected.isNull)
        return selected.get;
    else
        return conn.upsertSubstanceHurtsSequence(name, unit, pdk);
}

// При каждом вызове вызывает приращение sequence
private int upsertSubstanceHurtsSequence(Connection conn, string name, string unit, double pdk)
{
    auto qp = wrapStatement(
        `INSERT INTO substances (`,
            i("substance_name", name),
            i("unit", unit),
            i("pdk", pdk),
        `) VALUES(`, Dollars(), `)`,
        `ON CONFLICT (substance_name, unit, pdk)`,
        `DO UPDATE SET pdk = EXCLUDED.pdk`, // just for ensure what RETURNING always returns value
        `RETURNING substance_id`
    );

    auto r = conn.execStatement(qp);
    r.checkOneRowResult;

    return r[0][0].as!int;
}

private void upsertMeasurement(Connection conn, in SysTime time, short placeId, in Measurement m)
{
    import std.exception: enforce;

    enum PDK_ISNT_SET = -100000; /// обозначает что ПДК не была установлена

    // Проверка незанятости нашего внутреннего значения неустановленного ПДК
    enforce(m.pdk.isNull || m.pdk.get != PDK_ISNT_SET);

    const substanceId = conn.upsertSubstance(
        m.name,
        m.unit,
        m.pdk.isNull ? PDK_ISNT_SET : m.pdk.get
    );

    auto qp = wrapStatement(
        `INSERT INTO measurements (`,
            i("place_id", placeId),
            i("measurement_time", m.dateTime),
            i("substance_id", substanceId),
            i("value", m.value),
            i("recorded_time", time),
        `) VALUES(`, Dollars(), `)`,
        `ON CONFLICT (place_id, measurement_time, substance_id, value)`,
        `DO NOTHING`
    );

    conn.execStatement(qp);
}

void upsertMeasurementsToDB(PostgresClient client, in SysTime time, in Coords coords, string observatoryName, in Measurement[] measurements)
{
    client.pickConnection(
        (scope conn)
        {
            // для скорости транзакций, сохранность данных нам не особо важна здесь
            conn.execStatement("SET synchronous_commit TO OFF");

            const placeId = conn.upsertPlace(coords, observatoryName).to!short;

            foreach(const ref m; measurements)
                conn.upsertMeasurement(time, placeId, m);
        }
    );
}

private void checkOneRowResult(immutable Answer r) {
  if(r.length != 1)
    throw new SearchException(ExceptionType.NOT_ONE_ROW, r);
}

///
enum ExceptionType : ubyte {
  USER_NOT_FOUND = 0, ///
  ZERO_ROWS = 0, ///
  NOT_ONE_ROW, ///
  MORE_THAN_ONE_ROW, ///
}

class SearchException : Exception {
  const ExceptionType type;
  immutable Answer answer = null;

  /// for checkOneRow only
  this(ExceptionType t, immutable Answer a, string file = __FILE__, size_t line = __LINE__) {
    answer = a;

    this(t, answer.length, file, line);
  }

  //TODO: remove it
  ///
  this(ExceptionType t, long rowsNum, string file = __FILE__, size_t line = __LINE__) pure @safe {
    type = t;

    super(
      type.createExceptionMsg~`, not ` ~ rowsNum.to!string,
      file,
      line
    );
  }
}

private string createExceptionMsg(ExceptionType t) pure @safe {
    with(ExceptionType)
    final switch(t) {
      case ZERO_ROWS:
        return `Zero rows affected`;

      case NOT_ONE_ROW:
        return `Strictly one row should be affected`;

      case MORE_THAN_ONE_ROW:
        return `Not more than one row should be affected`;
    }
}
