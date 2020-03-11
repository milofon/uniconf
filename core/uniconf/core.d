/**
 * The module contains the objects and the properties of control functions
 *
 * Copyright: (c) 2015-2020, Milofon Project.
 * License: Subject to the terms of the BSD 3-Clause License, as written in the included LICENSE.md file.
 * Author: <m.galanin@milofon.pro> Maksim Galanin
 * Date: 2020-03-09
 */

module uniconf.core;

private
{
    import std.exception : enforce;

    import uninode.node : isUniNode;
    import uninode.tree : UniTree;
}


/// Config node
alias UniConf = UniTree;


/**
 * Thrown when an unhandled type is encountered.
 */
class UniConfException : Exception
{
    /**
     * common constructor
     */
    pure nothrow @safe @nogc
    this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable next = null)
    {
        super(msg, file, line, next);
    }
}

/// delegate reader config file
alias ConfigReader = string delegate(string filePath);

/// delegate loader config file
alias ConfigLoader = UniConf delegate(string data);


/**
 * Setting the function to read configuration files
 *
 * Params:
 * reader = Delegate reader
 */
void setConfigReader(ConfigReader reader)
{
    _configReader = reader;
}


/**
 * Register config file loader delegate
 *
 * Params:
 * fileExtensions = File extension to delermite the type loader
 * loader         = Loader delegate
 */
void registerConfigLoader(string[] fileExtensions, ConfigLoader loader)
{
    import std.algorithm.searching : canFind;

    ConfigFileLoader nextLoader = _configLoader;

    _configLoader = (string fileExt, string data) {
        if (fileExtensions.canFind(fileExt))
            return loader(data);
        else
            return nextLoader(fileExt, data);
    };
}


/**
 * The function loads the configuration object from a file
 * Params:
 *
 * filePath = File path
 */
UniConf loadConfig(string filePath) @safe
{
    import std.path : extension;

    string source = () @trusted {
        if (_configReader is null)
        {
            import std.file : readText, FileException;
            try
                return readText(filePath);
            catch (FileException e)
                throw new UniConfException("Error loading config from a file '"
                        ~ filePath ~ "'", e.file, e.line, e);
        }
        else
            return _configReader(filePath);
    } ();

    return () @trusted {
        return _configLoader(filePath.extension, source);
    } ();
}


@("Should work load config")
@system unittest
{
    import std.exception : collectExceptionMsg;
    const msg = collectExceptionMsg(loadConfig("dummy://file.txt"));
    assert (msg == "Error loading config from a file 'dummy://file.txt'");
    setConfigReader((string) {
            return `{"client": {"host": "localhost", "port": 44}}`;
        });

    registerConfigLoader([".yaml"], (string) {
            return UniConf(2);
        });

    registerConfigLoader([".json"], (string) {
            return UniConf(1);
        });

    assert (loadConfig("dummy://file.yaml") == UniConf(2));
    assert (loadConfig("dummy://file.json") == UniConf(1));
}


package:


alias enforceUniConf = enforce!UniConfException;


private:


alias ConfigFileLoader = UniConf delegate(string fileExt, string data);


/**
 * Configuration file reader
 */
__gshared ConfigReader _configReader;

/**
 * Configuration file loader
 */
__gshared ConfigFileLoader _configLoader = (string fileExt, string data) {
        throw new UniConfException("Not defined loader for '" ~ fileExt ~ "' format");
    };

