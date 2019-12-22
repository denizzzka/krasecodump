import vibe.data.json;
import vibe.core.log;
import std.datetime;
import std.exception;
import std.conv: to;
import std.typecons;

import std.stdio;

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

struct Observatory
{
    short cityId;
    short obsId;
    string name;
    double lat;
    double lon;
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
            o.lat = currOb[`lat`].get!double;
            o.lon = currOb[`lon`].get!double;

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
    Nullable!double pdk;
    string unit;
    double value;
    DateTime dateTime;
}

Measurement[] requestKrasecoData(short station)
{
    Json j = callKrasecology(`/api/v1/history?interval=0&postId=`~station.to!string).readJson;

    Measurement[] ret;

    foreach(const ref substance; j.byValue)
    {
        writeln(">>> ", substance);

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
            mItem.dateTime = DateTime.fromISOExtString(timeStr);

            ret ~= mItem;

            writeln("=== ", mItem);
        }
    }

    return ret;
}

void main()
{
    requestObservatories.writeln;

    //~ 3.requestKrasecoData;
}
