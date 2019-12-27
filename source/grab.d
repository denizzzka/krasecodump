module krasecodump.grab;

import vibe.data.json;
import vibe.core.log;
import std.datetime;
import std.exception;
import std.conv: to;
import std.typecons;

auto callKrasecology(string uri)
{
    import vibe.http.client;

    const url = `http://mobile.krasecology.ru`~uri;

    return requestHTTP(url,
        (scope rq) {
            rq.method = HTTPMethod.GET;
            rq.headers["User-Agent"] = "okhttp/3.12.0";
            rq.headers["Connection"] = "close";

            assert(!rq.persistent);
        },
    );
}

struct Meteo
{
    Nullable!double t;
    Nullable!double ws;
    Nullable!double wd;
    Nullable!double hum;
    Nullable!double p;
}

struct Coords
{
    double lat;
    double lon;
}

struct Observatory
{
    short cityId;
    short obsId;
    string name;
    Coords coords;
    Meteo meteo;
}

Observatory[] requestObservatories()
{
    Json j = callKrasecology(`/api/v1/index`).readJson;

    Observatory[] ret;

    foreach(const ref city; j["cities"].byValue)
    {
        const short cityId = city["id"].get!short;

        foreach(const ref currOb; city["observatories"].byValue)
        {
            Observatory o;
            o.cityId = cityId;
            o.obsId = currOb[`id`].get!short;
            o.name = currOb[`name`].get!string;
            o.coords.lat = currOb[`lat`].get!double;
            o.coords.lon = currOb[`lon`].get!double;

            const meteoJson = currOb[`meteo`];

            o.meteo = deserialize!(JsonSerializer, Meteo)(meteoJson);

            ret ~= o;
        }
    }

    return ret;
}

struct Measurement
{
    string name;
    string unit;
    double value;
    SysTime dateTime;
    Nullable!double pdk;
}

Measurement[] requestKrasecoData(short station)
{
    Json j = callKrasecology(`/api/v1/history?interval=0&postId=`~station.to!string).readJson;

    Measurement[] ret;

    foreach(const ref substance; j.byValue)
    {
        Measurement m;
        m.name = substance[`element`].get!string;
        m.unit = substance[`unit`].get!string;

        Json pdk = substance[`pdk`];
        if(pdk.type != Json.Type.null_)
            m.pdk = pdk.get!double;

        foreach(const ref item; substance[`items`].byValue)
        {
            Measurement mItem = m;

            mItem.value = item[`value`].get!double;

            import std.datetime;

            string timeStr = item[`captured_at`].get!string;
            mItem.dateTime = SysTime(
                // Конвертация Красноярского времени в универсальное
                DateTime.fromISOExtString(timeStr), PosixTimeZone.getTimeZone("Asia/Krasnoyarsk")
            );

            ret ~= mItem;
        }
    }

    return ret;
}
