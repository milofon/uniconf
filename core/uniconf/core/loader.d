/**
 *
 *
 * Copyright: (c) 2015-2018, Milofon Project.
 * License: Subject to the terms of the BSD 3-Clause License, as written in the included LICENSE.md file.
 * Author: <m.galanin@milofon.pro> Maksim Galanin
 * Date: 2018-09-03
 */

module uniconf.core.loader;

public
{
    import uniconf.core.config : Config;
}

private
{
    import std.path : extension;
    import std.algorithm.searching : canFind;

    import uniconf.core.exception : ConfigException, enforceConfig;
}


/**
 * Interface config loader of type
 */
interface LangConfigLoader
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
Config loadConfig(LangConfigLoader[] loaders, string fileName)
{
    foreach(LangConfigLoader loader; loaders)
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
alias ConfigLoader = Config delegate(string fileName);


/**
 * Create properties loader
 */
ConfigLoader createConfigLoader(LangConfigLoader[] loaders)
{
    enforceConfig(loaders.length, "Loaders is empty");
    return (string fileName)
    {
        return loadConfig(loaders, fileName);
    };
}

