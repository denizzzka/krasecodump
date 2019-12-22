import krasecodump.grab;
import std.stdio;
import vibe.db.postgresql;

void main(string[] args)
{
    const postgresConnString = args[1];
    auto dbClient = new PostgresClient(postgresConnString, 5);

    auto obs = requestObservatories;

    foreach(const ref o; obs)
    {
        const data = o.obsId.requestKrasecoData;
    }
}
