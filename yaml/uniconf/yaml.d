/**
 * YAML configuration module
 *
 * Copyright: (c) 2015-2020, Milofon Project.
 * License: Subject to the terms of the BSD 3-Clause License, as written in the included LICENSE.md file.
 * Author: <m.galanin@milofon.pro> Maksim Galanin
 * Date: 2018-09-03
 */

module uniconf.yaml;

private
{
    import std.array : appender, replace;
    import std.datetime.systime : SysTime;
    import std.datetime : DateTimeException;

    import dyaml.loader : Loader;
    import dyaml.node : Node, NodeType;
    import dyaml.exception : YAMLException;
    import dyaml.dumper : dumper;
    import dyaml.style : ScalarStyle;

    import uniconf.core : UniConfException;
    import uninode.node : isUniNode;
}


/**
 * Conert Yaml to UniConf
 */
UniConf toUniConf(UniConf)(auto ref const Node root) @safe
    if (isUniNode!UniConf)
{
    UniConf convert(ref const Node node) @safe
    {
        if (!node.isValid)
            return UniConf();

        switch(node.type)
        {
            case NodeType.null_:
            case NodeType.merge:
            case NodeType.invalid:
                return UniConf();
            case NodeType.boolean:
                return UniConf(node.get!bool);
            case NodeType.integer:
                return UniConf(node.get!long);
            case NodeType.decimal:
                return UniConf(node.get!double);
            case NodeType.binary:
                return UniConf(node.get!(ubyte[]));
            case NodeType.timestamp:
                return UniConf(node.get!SysTime.toISOExtString);
            case NodeType.string:
            {
                auto style = __traits(getMember,  node, "scalarStyle");
                if (style == ScalarStyle.folded)
                    return UniConf(node.get!string.replace("\n", " "));
                return UniConf(node.get!string);
            }
            case NodeType.mapping:
            {
                UniConf[string] map;
                foreach(string key, ref const Node value; node)
                    map[key] = convert(value);
                return UniConf(map);
            }
            case NodeType.sequence:
            {
                UniConf[] arr = new UniConf[node.length];
                size_t i;
                foreach(ref const Node value; node)
                    arr[i++] = convert(value);
                return UniConf(arr);
            }
            default:
                return UniConf();
        }
    }

    return convert(root);
}


/**
 * Convert UniConf to Yaml
 */
Node toYaml(UniConf)(auto ref const UniConf root) @safe
    if (isUniNode!UniConf)
{
    Node convert(ref const UniConf node) @trusted
    {
        switch(node.tag)
        {
            case UniConf.Tag.nil:
                return Node();
            case UniConf.Tag.boolean:
                return Node(node.get!bool);
            case UniConf.Tag.integer:
                return Node(node.get!long);
            case UniConf.Tag.uinteger:
                return Node(node.get!ulong);
            case UniConf.Tag.floating:
                return Node(node.get!double);
            case UniConf.Tag.text:
            {
                string val = node.get!string;
                try
                    return Node(SysTime.fromISOExtString(val));
                catch (DateTimeException e)
                    return Node(node.get!string);
            }
            case UniConf.Tag.sequence:
            {
                size_t len = node.length;
                Node[] arr = new Node[len];
                foreach(size_t i, ref const UniConf ch; node)
                    arr[i] = convert(ch);
                return Node(arr);
            }
            case UniConf.Tag.mapping:
            {
                Node[string] map;
                foreach (string key, ref const UniConf ch; node)
                    map[key] = convert(ch);
                return Node(map);
            }
            default:
                return Node();
        }
    }

    return convert(root);
}


@("Should work convert yaml to config and back")
@safe unittest
{
    import uninode.node : UniNode;
    const val = Node([Node(1), Node("hello"), Node(["one": Node(1)])]);
    const conf = val.toUniConf!UniNode();
    const yml = conf.toYaml();
    assert (yml == val);
}


/**
 * Parse UniConf from string
 */
UniConf parseYaml(UniConf)(string data) @safe
    if (isUniNode!UniConf)
{
    Node root;
    try
        root = Loader.fromString(data.idup).load();
    catch(YAMLException e)
        throw new UniConfException("Error loading yaml from a string:",
                e.file, e.line, e);
    return toUniConf!UniConf(root);
}


/**
 * Convert UniConf to json string
 */
string saveYaml(UniConf)(auto ref const UniConf node) @safe
    if (isUniNode!UniConf)
{
    const yml = toYaml!UniConf(node);
    auto buffer = appender!string;
    dumper().dump(buffer, yml);
    return buffer.data;
}

@("Should work parseYaml and saveYaml method")
@safe unittest
{
    import uninode.tree : UniTree;

    enum yamlSrc = `
client:
    host: "localhost"
    port: 404
    can: 2001-12-15T02:59:43.1Z
    collection:
    - "one"
    - "two"
`;

    UniTree conf = parseYaml!UniTree(yamlSrc);
    assert (conf.get!int("client.port") == 404);
    assert (conf.get!string("client.host") == "localhost");
    const yml = saveYaml(conf);
    conf = parseYaml!UniTree(yml);
    assert (conf.get!int("client.port") == 404);
    assert (conf.get!string("client.host") == "localhost");
}

