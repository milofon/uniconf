/**
 * YAML Loader
 *
 * Copyright: (c) 2015-2018, Milofon Project.
 * License: Subject to the terms of the BSD 3-Clause License, as written in the included LICENSE.md file.
 * Author: <m.galanin@milofon.pro> Maksim Galanin
 * Date: 2018-09-03
 */

module uniconf.yaml;

private
{
    import dyaml.loader : Loader;
    import dyaml.node : Node;
    import dyaml.exception : YAMLException;

    import uniconf.loader;
    import uniconf.exception;
}


/**
 * The loader data from a YAML file
 */
class YamlConfigLoader : ConfigLoader
{

    Config loadConfigFile(string fileName)
    {
        Node root;

        try
            root = Loader(fileName).load();
        catch(YAMLException e)
            throw new ConfigException("Error loading yaml from a file '"
                    ~ fileName ~ "':", e.file, e.line, e);

        return toConfig(root);
    }


    Config loadConfigString(string data)
    {
        Node root;

        try
            root = Loader((cast(ubyte[])data).dup).load();
        catch(YAMLException e)
            throw new ConfigException("Error loading yaml from a string:",
                    e.file, e.line, e);

        return toConfig(root);
    }


    string[] getExtensions()
    {
        return [".yml", ".yaml"];
    }


    private Config toConfig(Node root)
    {
        Config convert(Node node)
        {
            if (!node.isValid)
                return Config();
            else if (node.isInt)
                return Config(node.get!long);
            else if (node.isFloat)
                return Config(node.get!double);
            else if (node.isString)
                return Config(node.get!string);
            else if (node.isBool)
                return Config(node.get!bool);
            else if (node.isMapping)
            {
                Config[string] map;
                foreach(string key, Node value; node)
                    map[key] = convert(value);

                return Config(map);
            }
            else if (node.isSequence)
            {
                Config[] arr;
                foreach(Node value; node)
                    arr ~= convert(value);

                return Config(arr);
            }
            else
                return Config();
        }

        return convert(root);
    }
}



unittest
{
    auto loader = new YamlConfigLoader();
    auto conf = loader.loadConfigString(`
ключевое-слово: ')'
предложение: абзац
`);

    assert("предложение" in conf);
    assert(conf.get!string("предложение") == "абзац");
}

