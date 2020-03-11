/**
 * JSON module
 *
 * Copyright: (c) 2015-2020, Milofon Project.
 * License: Subject to the terms of the BSD 3-Clause License, as written in the included LICENSE.md file.
 * Author: <m.galanin@milofon.pro> Maksim Galanin
 * Date: 2020-03-09
 */

module uniconf.json;

private
{
    import std.json : JSONValue, JSONType, parseJSON, JSONException, toJSON;

    import uniconf.core : UniConfException;
    import uninode.node : isUniNode;
}


/**
 * Conert Json to UniConf
 */
UniConf toUniConf(UniConf)(auto ref const JSONValue root) pure @safe
    if (isUniNode!UniConf)
{
    UniConf convert(ref const JSONValue node) pure @trusted
    {
        switch(node.type)
        {
            case JSONType.NULL:
                return UniConf();
            case JSONType.TRUE:
                return UniConf(true);
            case JSONType.FALSE:
                return UniConf(false);
            case JSONType.INTEGER:
                return UniConf(node.integer);
            case JSONType.UINTEGER:
                return UniConf(node.uinteger);
            case JSONType.FLOAT:
                return UniConf(node.floating);
            case JSONType.STRING:
                return UniConf(node.str);
            case JSONType.ARRAY:
            {
                size_t len = node.array.length;
                UniConf[] arr = new UniConf[len];
                foreach(size_t i, JSONValue ch; node.array)
                    arr[i] = convert(ch);
                return UniConf(arr);
            }
            case JSONType.OBJECT:
            {
                UniConf[string] map;
                foreach (string key, JSONValue ch; node.object)
                    map[key] = convert(ch);
                return UniConf(map);
            }
            default:
                return UniConf();
        }
    }

    return convert(root);
}


/**
 * Convert UniConf to Json
 */
JSONValue toJson(UniConf)(auto ref const UniConf root) @safe
    if (isUniNode!UniConf)
{
    JSONValue convert(ref const UniConf node) @trusted
    {
        switch(node.tag)
        {
            case UniConf.Tag.nil:
                return JSONValue();
            case UniConf.Tag.boolean:
                return JSONValue(node.get!bool);
            case UniConf.Tag.integer:
                return JSONValue(node.get!long);
            case UniConf.Tag.uinteger:
                return JSONValue(node.get!ulong);
            case UniConf.Tag.floating:
                return JSONValue(node.get!double);
            case UniConf.Tag.text:
                return JSONValue(node.get!string);
            case UniConf.Tag.sequence:
            {
                size_t len = node.length;
                JSONValue[] arr = new JSONValue[len];
                foreach(size_t i, ref const UniConf ch; node)
                    arr[i] = convert(ch);
                return JSONValue(arr);
            }
            case UniConf.Tag.mapping:
            {
                JSONValue[string] map;
                foreach (string key, ref const UniConf ch; node)
                    map[key] = convert(ch);
                return JSONValue(map);
            }
            default:
                return JSONValue();
        }
    }

    return convert(root);
}

@("Should work convert json to config and back")
@safe unittest
{
    import uninode.node : UniNode;

    const val = JSONValue([JSONValue(1), JSONValue("hello"), JSONValue(["one": JSONValue(1)])]);
    const conf = val.toUniConf!UniNode();
    const js = conf.toJson();
    assert (js == val);
}


/**
 * Parse UniConf from string
 */
UniConf parseJson(UniConf)(string data) @safe
    if (isUniNode!UniConf)
{
    JSONValue root;
    try
        root = parseJSON(data);
    catch (JSONException e)
        throw new UniConfException("Error loading json from a string:",
                e.file, e.line, e);
    return toUniConf!UniConf(root);
}


/**
 * Convert UniConf to json string
 */
string saveJson(UniConf)(auto ref const UniConf node, bool pretty=false) @safe
{
    const json = toJson!UniConf(node);
    return toJSON(json, pretty);
}

@("Should work parseJson and saveJson method")
@safe unittest
{
    import uninode.tree : UniTree;

    enum json = `{"client":{"host":"localhost","port":44}}`;

    const conf = json.parseJson!UniTree;
    assert (conf.get!int("client.port") == 44);
    assert (conf.get!string("client.host") == "localhost");

    const js = saveJson(conf);
    assert (js == json);
}

