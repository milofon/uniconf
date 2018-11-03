/**
 * Copyright: (c) 2015-2018, Milofon Project.
 * License: Subject to the terms of the BSD 3-Clause License, as written in the included LICENSE.md file.
 * Author: <m.galanin@milofon.pro> Maksim Galanin
 * Date: 2018-10-15
 */

module uniconf.loaders;

private
{
    import dunit;

    import uniconf : ConfigLoaderMixin;
    import uniconf.core;
}



class TestLoaders
{

    mixin UnitTest;


    @Test
    void testAvailableLoaders()
    {
        mixin ConfigLoaderMixin!();
        auto loaders = getAvailableLoaders();
        assertEquals(loaders.length, 5);
    }


    @Test
    void testLoadJson()
    {
        import uniconf.json;
        auto loader = new JsonConfigLoader();
        auto config = loader.loadConfigFile("test/files/config.json");
        checkLoadedConfig(config);
    }


    @Test
    void testLoadSDLang()
    {
        import uniconf.sdlang;
        auto loader = new SdlangConfigLoader();
        auto config = loader.loadConfigFile("test/files/config.sdl");
        checkLoadedConfig(config);
    }


    @Test
    void testLoadYaml()
    {
        import uniconf.yaml;
        auto loader = new YamlConfigLoader();
        auto config = loader.loadConfigFile("test/files/config.yml");
        checkLoadedConfig(config);
    }


    @Test
    void testLoadProperties()
    {
        import uniconf.properd;
        auto loader = new PropertiesConfigLoader();
        auto config = loader.loadConfigFile("test/files/config.properties");
        checkLoadedConfig(config);
    }


    @Test
    void testLoadToml()
    {
        import uniconf.toml;
        auto loader = new TomlConfigLoader();
        auto config = loader.loadConfigFile("test/files/config.toml");
        checkLoadedConfig(config);
    }


private:


    void checkLoadedConfig(Config config)
    {
        assertFalse(config.get!int("numbers.one").isNull);
        assertTrue(config.get!int("numbers.four").isNull);

        assertNotNull("one" in config.getObject("numbers"));
        assertNull("five" in config.getObject("numbers"));

        assertEquals(config.getArray("list").length, 3);

        assertEquals(config.get!string("title"), "loader");
        assertEquals(config.get!float("score"), 2.333f);
    }
}

