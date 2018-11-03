/**
 * Copyright: (c) 2015-2018, Milofon Project.
 * License: Subject to the terms of the BSD 3-Clause License, as written in the included LICENSE.md file.
 * Author: <m.galanin@milofon.pro> Maksim Galanin
 * Date: 2018-09-04
 */

module uniconf.core;

public
{
    import uniconf.core.config : Config;
    import uniconf.core.loader;
    import uniconf.core.exception;
}


/**
 * Mixin available loaders
 */
mixin template ConfigLoaderMixin()
{
    private LangConfigLoader[] getAvailableLoaders()
    {
        LangConfigLoader[] loaders;

        version(Have_uniconf_sdlang)
        {
            import uniconf.sdlang : SdlangConfigLoader;
            loaders ~= new SdlangConfigLoader();
        }
        version (Have_uniconf_properd)
        {
            import uniconf.properd : PropertiesConfigLoader;
            loaders ~= new PropertiesConfigLoader();
        }
        version (Have_uniconf_json)
        {
            import uniconf.json : JsonConfigLoader;
            loaders ~= new JsonConfigLoader();
        }
        version (Have_uniconf_yaml)
        {
            import uniconf.yaml : YamlConfigLoader;
            loaders ~= new YamlConfigLoader();
        }
        version (Have_uniconf_toml)
        {
            import uniconf.toml : TomlConfigLoader;
            loaders ~= new TomlConfigLoader();
        }

        return loaders;
    }
}

