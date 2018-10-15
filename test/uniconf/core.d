/**
 * Copyright: (c) 2015-2018, Milofon Project.
 * License: Subject to the terms of the BSD 3-Clause License, as written in the included LICENSE.md file.
 * Author: <m.galanin@milofon.pro> Maksim Galanin
 * Date: 2018-10-15
 */

module uniconf.core_test;

private
{
    import dunit;

    import uniconf.core;
}


class TestConfig
{

    mixin UnitTest;


    @Test
    void testFunctionDefaultValue()
    {
        string val;
        void fun(Config conf = Config(""))
        {
            val = conf.get!string;
        }

        fun();
        assertEquals(val, "");
        fun(Config("1"));
        assertEquals(val, "1");
    }


    @Test
    void testCreateEmptyLoader()
    {
        auto exp = expectThrows!ConfigException(createConfigLoader([]));
        assertEquals("Loaders is empty", exp.msg);
    }
}

