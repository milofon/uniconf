/**
 * JavaProperties Loader
 *
 * Copyright: (c) 2015-2018, Milofon Project.
 * License: Subject to the terms of the BSD 3-Clause License, as written in the included LICENSE.md file.
 * Author: <m.galanin@milofon.pro> Maksim Galanin
 * Date: 2018-09-03
 */

module uniconf.properd;

private
{
    import std.array : split, empty, front;
    import std.conv : to;

    import properd;
    import uniconf.core.loader;
    import uniconf.core.exception;
}


/**
 * The loader data from a .properties file
 */
class PropertiesConfigLoader : ConfigLoader
{
    Config loadConfigFile(string fileName)
    {
        string[string] root;

        try
            root = readProperties(fileName);
        catch (PropertyException e)
            throw new ConfigException("Error loading properties from a file '"
                    ~ fileName ~ "':", e.file, e.line, e);

        return toConfig(root);
    }


    Config loadConfigString(string data)
    {
        string[string] root;

        try
            root = parseProperties(data);
        catch(PropertyException e)
            throw new ConfigException("Error loading properties from string:",
                    e.file, e.line, e);

        return toConfig(root);
    }


    string[] getExtensions()
    {
        return [".properties"];
    }


private:


    Config toConfig(string[string] root)
    {
        Config ret = Config.emptyObject;

        void setConfigValue(Config val, Config* root, string fullKey)
        {
            void setConfig(Config* current, string[] names)
            {
                if (names.empty)
                    return;

                string name = names[0];

                if (current.kind == Config.Kind.object)
                {
                    if (auto chd = name in *current)
                    {
                        if (names.length == 1)
                            (*chd)["v"] = val;
                        else
                            setConfig(chd, names[1..$]);
                    }
                    else
                    {
                        if (names.length == 1)
                            (*current)[name] = val;
                        else
                        {
                            auto map = Config.emptyObject;
                            setConfig(&map, names[1..$]);
                            (*current)[name] = map;
                        }
                    }
                }
            }

            setConfig(root, fullKey.split('.'));
        }

        foreach (string fullKey, string val; root)
            setConfigValue(convertValue(val), &ret, fullKey);

        return ret;
    }


    Config convertValue(string value)
    {
        if (value == "false")
            return Config(false);
        else if (value == "true")
            return Config(true);
        else if (value == "null")
            return Config(null);
        else
        {
            switch (value.front)
            {
                case '-':
                case '0': .. case '9':
                    bool is_long_overflow;
                    bool is_float;
                    auto num = skipNumber(value, is_float, is_long_overflow);
                    if (is_float)
                        return Config(to!double(num));
                    else
                        return Config(to!long(num));
                default:
                    return Config(value);
            }
        }
    }
}


private:


/**
 * Parse value
 * get from vibe.d
 */
string skipNumber(R)(ref R s, out bool is_float, out bool is_long_overflow)
{
    size_t idx = 0;
    is_float = false;
    is_long_overflow = false;
    ulong int_part = 0;
    if (s[idx] == '-') idx++;
    if (s[idx] == '0') idx++;
    else {
        configEnforce(isDigit(s[idx]), "Digit expected at beginning of number.");
        int_part = s[idx++] - '0';
        while( idx < s.length && isDigit(s[idx]) )
        {
            if (!is_long_overflow)
            {
                auto dig = s[idx] - '0';
                if ((long.max / 10) > int_part || ((long.max / 10) == int_part && (long.max % 10) >= dig))
                {
                    int_part *= 10;
                    int_part += dig;
                }
                else
                {
                    is_long_overflow = true;
                }
            }
            idx++;
        }
    }

    if( idx < s.length && s[idx] == '.' ){
        idx++;
        is_float = true;
        while( idx < s.length && isDigit(s[idx]) ) idx++;
    }

    if( idx < s.length && (s[idx] == 'e' || s[idx] == 'E') ){
        idx++;
        is_float = true;
        if( idx < s.length && (s[idx] == '+' || s[idx] == '-') ) idx++;
        configEnforce( idx < s.length && isDigit(s[idx]), "Expected exponent." ~ s[0 .. idx]);
        idx++;
        while( idx < s.length && isDigit(s[idx]) ) idx++;
    }

    string ret = s[0 .. idx];
    s = s[idx .. $];
    return ret;
}



bool isDigit(dchar ch) @safe nothrow pure
{
    return ch >= '0' && ch <= '9';
}



unittest
{
    auto loader = new PropertiesConfigLoader();
    auto conf = loader.loadConfigString(`
integer_123 = 123
integer_0 = 0
integer_1 = 1
bool_false = false
bool_true = true
val_null = null
server.host = localhost
server.port = 44
client.url = http://localhost:5000

client.url.schema = "http"
client.url.host = "localhost"
client.url.port = 5000
`);

    assert(conf.get!string("client.url.v") == "http://localhost:5000");
    assert(conf.get!int("client.url.port") == 5000);
}

