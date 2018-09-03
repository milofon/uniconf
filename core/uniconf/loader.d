/**
 *
 *
 * Copyright: (c) 2015-2018, Milofon Project.
 * License: Subject to the terms of the BSD 3-Clause License, as written in the included LICENSE.md file.
 * Author: <m.galanin@milofon.pro> Maksim Galanin
 * Date: 2018-09-03
 */

module uniconf.loader;

public
{
    import uniconf.config : Config;
}

private
{
    import std.path : extension;
    import std.algorithm.searching : canFind;

    import uniconf.exception : ConfigException;
}


/**
 * Interface config loader
 */
interface ConfigLoader
{
    /**
     * Loading properties from a file
     *
     * Params:
     *
     * fileName = Path to the file system
     */
    Config loadConfigFile(string fileName);


    /**
     * Loading properties from a string
     *
     * Params:
     *
     * data = Source string
     */
    Config loadConfigString(string data);


    /**
     * Returns the file extension to delermite the type loader
     */
    string[] getExtensions();


    /**
     * Checking the possibility to download the file current loader
     *
     * Verification occurs by file extension
     *
     * Params:
     *
     * fileName = File
     */
    final bool isPropertiesFile(string fileName)
    {
        return canFind(getExtensions(), fileName.extension);
    }
}


/**
 * Loading config from the file with the necessary loader
 *
 * Params:
 *
 * loaders  = Loaders
 * fileName = Path
 */
Config loadConfig(ConfigLoader[] loaders, string fileName)
{
    foreach(ConfigLoader loader; loaders)
        if (loader.isPropertiesFile(fileName))
            return loader.loadConfigFile(fileName);
    throw new ConfigException("Not defined loader for " ~ fileName);
}


/**
 * The function loads the configuration object from a file
 * Params:
 *
 * fileName = File name
 */
alias Loader = Config delegate(string fileName);



void registerLoader(shared ConfigLoader loader)
{
    synchronized {
        _loaders ~= loader;
    }
}


/**
 * Create properties loader
 */
Loader createConfigLoader()
{
    ConfigLoader[] loaders = cast(ConfigLoader[])_loaders;
    return (string fileName)
    {
        return loadConfig(loaders, fileName);
    };
}


private:


shared ConfigLoader[] _loaders;

