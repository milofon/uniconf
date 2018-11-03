/**
 * Toml Loader
 *
 * Copyright: (c) 2015-2018, Milofon Project.
 * License: Subject to the terms of the BSD 3-Clause License, as written in the included LICENSE.md file.
 * Author: <m.galanin@milofon.pro> Maksim Galanin
 * Date: 2018-09-03
 */

module uniconf.toml;

private
{
    import std.file : FileException, readText;

    import toml;

    import uniconf.core.loader;
    import uniconf.core.exception;
}


/**
 * The loader data from a .toml file
 */
class TomlConfigLoader : LangConfigLoader
{
    /**
     * Load config from file
     */
    Config loadConfigFile(string fileName)
    {
        try
        {
            string source = readText(fileName);
            return loadConfigString(source);
        }
        catch (FileException e)
            throw new ConfigException("Error loading toml from a file '"
                    ~ fileName ~ "':", e.file, e.line, e);
    }

    /**
     * Load config from string
     */
    Config loadConfigString(string data)
    {
        TOMLDocument root;

        try
            root = parseTOML(data);
        catch (TOMLParserException e)
            throw new ConfigException("Error loading toml from string:",
                    e.file, e.line, e);

        return toConfig(root);
    }


    string[] getExtensions()
    {
        return [".toml"];
    }


    private Config toConfig(TOMLDocument root)
    {
        Config convert(TOMLValue node)
        {
            switch(node.type)
            {
                case TOML_TYPE.TRUE:
                    return Config(true);
                case TOML_TYPE.FALSE:
                    return Config(false);
                case TOML_TYPE.INTEGER:
                    return Config(node.integer);
                case TOML_TYPE.FLOAT:
                    return Config(node.floating);
                case TOML_TYPE.STRING:
                    return Config(node.str);
                case TOML_TYPE.ARRAY:
                {
                    Config[] arr;
                    foreach(TOMLValue ch; node.array)
                        arr ~= convert(ch);
                    return Config(arr);
                }
                case TOML_TYPE.TABLE:
                {
                    Config[string] map;
                    foreach (string key, TOMLValue ch; node.table)
                        map[key] = convert(ch);
                    return Config(map);
                }
                default:
                    return Config();
            }
        }

        return convert(TOMLValue(root.table));
    }
}



@system unittest
{
    auto loader = new TomlConfigLoader();
    auto conf = loader.loadConfigString(`
[logger]
name="console"
appender="console"
level="debugv"
`);

    assert("logger.name" in conf);
    assert("logger.level" in conf);
    assert(conf.get!string("logger.level") == "debugv");
}

