/**
 * SDLang configuration module
 *
 * Copyright: (c) 2015-2020, Milofon Project.
 * License: Subject to the terms of the BSD 3-Clause License, as written in the included LICENSE.md file.
 * Author: <m.galanin@milofon.pro> Maksim Galanin
 * Date: 2018-09-03
 */

module uniconf.sdlang;

private
{
    import std.algorithm.searching : any;
    import std.array : empty;

    import sdlang : Tag, parseSource, ParseException, Value, Attribute;

    import uniconf.core : UniConfException;
    import uninode.node : isUniNode;
}


/**
 * Conert SDL to UniConf
 */
UniConf toUniConf(UniConf)(auto ref Tag root) @safe
    if (isUniNode!UniConf)
{
    UniConf convertVal(ref Value val) @trusted
    {
        if (val.convertsTo!bool)
            return UniConf(val.get!bool);
        else if (val.convertsTo!long)
            return UniConf(val.get!long);
        else if (val.convertsTo!string)
            return UniConf(val.get!string);
        else if (val.convertsTo!double)
            return UniConf(val.get!double);
        else if (val.convertsTo!(ubyte[]))
            return UniConf(val.get!(ubyte[]));
        else
            return UniConf();
    }

    UniConf convert(ref Tag tag) @trusted
    {
        // annonymous tag return values
        if (tag.tags.empty && tag.attributes.empty && tag.values.length)
        {
            if (tag.values.length == 1)
                return convertVal(tag.values[0]);
            else
            {
                UniConf[] arr = new UniConf[tag.values.length];
                foreach (size_t i, Value v; tag.values)
                    arr[i] = convertVal(v);
                return UniConf(arr);
            }
        }

        // if exists tags or attributes then mapping
        if (tag.tags.length || tag.attributes.length)
        {
            UniConf[string] map;
            UniConf[] values;

            foreach(Attribute a; tag.attributes)
                map[a.name] = convertVal(a.value);

            if (tag.values.length == 1 && tag.values[0].convertsTo!string)
                map["__name"] = convertVal(tag.values[0]);
            else
            {
                values.reserve(tag.values.length);
                foreach (Value val; tag.values)
                    values ~= convertVal(val);
            }

            foreach (Tag subTag; tag.tags)
            {
                auto subNode = convert(subTag);
                if (subTag.name.empty)
                    values ~= subNode;
                else
                {
                    if (auto exNode = subTag.name in map)
                    {
                        if (exNode.canSequence)
                            *exNode ~= subNode;
                        else if (subTag.name != "__name")
                            map[subTag.name] = UniConf([*exNode, subNode]);
                    }
                    else
                        map[subTag.name] = subNode;
                }
            }

            if (values.length)
                map["__values"] = UniConf(values);

            return UniConf(map);
        }
        else
            return UniConf();
    }

    return convert(root);
}


/**
 * Convert UniConf to SDLang
 */
Tag toSDLang(UniConf)(auto ref const UniConf root) @safe 
    if (isUniNode!UniConf)
{
    Value convertNode(UniConf node)
    {
        switch(node.tag)
        {
            case UniConf.Tag.nil:
                return Value();
            case UniConf.Tag.boolean:
                return Value(cast()node.get!bool);
            case UniConf.Tag.integer:
                return Value(cast()node.get!long);
            case UniConf.Tag.uinteger:
                return Value(cast(long)node.get!ulong);
            case UniConf.Tag.floating:
                return Value(cast()node.get!double);
            case UniConf.Tag.text:
                return Value(cast()node.get!string);
            case UniConf.Tag.raw:
                return Value(cast(ubyte[])node.get!(ubyte[]));
            default:
                return Value();
        }
    }

    Tag convert(ref const UniConf node) @trusted
    {
        Tag ret = new Tag();

        if (node.canSequence)
        {
            foreach (ref const UniConf subNode; node)
            {
                if (subNode.canSequence || subNode.canMapping)
                    ret.add(convert(subNode));
                else
                    ret.add(convertNode(subNode));
            }
        }
        else if (node.canMapping)
        {
            foreach (string name, ref const UniConf subNode; node)
            {
                if (subNode.canSequence && subNode.getSequence.any!((n) => n.canMapping))
                {
                    foreach (ref const UniConf subSubNode; subNode)
                    {
                        Tag subTag = convert(subSubNode);
                        subTag.name = name;
                        ret.add(subTag);
                    }
                }
                else if (name == "__values")
                {
                    foreach (ref const UniConf subVal; subNode)
                    {
                        if (subVal.canSequence || subVal.canMapping)
                            ret.add(convert(subVal));
                        else
                            ret.add(convertNode(subVal));
                    }
                }
                else if (name == "__name")
                {
                    if (subNode.canSequence && subNode.getSequence.length)
                        ret.add(convertNode(subNode[0]));
                    else
                        ret.add(convertNode(subNode));
                }
                else
                {
                    Tag subTag = convert(subNode);
                    subTag.name = name;
                    ret.add(subTag);
                }
            }
        }
        else
            ret.add(convertNode(node));

        return ret;
    }

    return () @trusted {
        Tag ret = convert(root);
        if (ret.tags.length == 0 && ret.values.length > 0)
        {
            Tag rootTag = new Tag();
            rootTag.add(ret);
            return rootTag;
        }
        return ret;
    } ();
}

@("Should work convert sdl to config and back")
@system unittest
{
    import uninode.tree : UniTree;

    enum sdl = `
"anno1" 1
logger "console" {
    appender "console"
    level "debugv"
    item "node1" {
        order 1
    }
    item "node2"
    item "node3"
}
`;

    UniTree conf = parseSDLang!UniTree(sdl);
    Tag sdlRoot = toSDLang(conf);
    assert (sdlRoot.tags.length == 2);
    assert (sdlRoot.tags[1].values.length == 2);
    assert (sdlRoot.tags[1].values[0].get!string == "anno1");

    assert (sdlRoot.tags[0].values.length == 1);
    assert (sdlRoot.tags[0].values[0].get!string == "console");
    assert (sdlRoot.tags[0].tags.length == 5);
}


/**
 * Parse UniConf from string
 */
UniConf parseSDLang(UniConf)(string data) @trusted
    if (isUniNode!UniConf)
{
    Tag root;
    try
        root = parseSource(data);
    catch(ParseException e)
        throw new UniConfException("Error loading sdlang from string:",
                e.file, e.line, e);
    return toUniConf!UniConf(root);
}


/**
 * Convert UniConf to json string
 */
string saveSDLang(UniConf)(auto ref const UniConf node, string indent="    ") @trusted
{
    auto rootTag = toSDLang!UniConf(node);
    return rootTag.toSDLDocument(indent);
}

@("Should work parseSDLang and saveSDLang method")
@safe unittest
{
    import uninode.tree : UniTree;

    enum sdl = `client {
    host "localhost"
    port 44L
}
`;

    const conf = parseSDLang!UniTree(sdl);
    assert (conf.get!int("client.port") == 44);
    assert (conf.get!string("client.host") == "localhost");
    const sdls = saveSDLang(conf);
    assert (sdl == sdls);
}

