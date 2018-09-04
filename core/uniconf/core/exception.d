/**
 * Exception module
 *
 * Copyright: (c) 2015-2018, Milofon Project.
 * License: Subject to the terms of the BSD 3-Clause License, as written in the included LICENSE.md file.
 * Author: <m.galanin@milofon.pro> Maksim Galanin
 * Date: 2018-09-03
 */

module uniconf.core.exception;

private
{
    import std.format : fmt = format;
    import std.exception : enforce;

    import uniconf.core.config : Config;
}


/**
 * Loading config exception
 */
class ConfigException : Exception
{
    this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable next = null)
    {
        super(msg ~ ((next !is null) ? "\n" ~ next.msg : ""), file, line, next);
    }
}


/**
 * Manipulate config exception
 */
class ConfigNotFoundException : Exception
{
    this(Config conf, string name, string file = __FILE__, size_t line = __LINE__)
    {
        super(fmt!"Property '%s' not found (%s)"(name, conf), file, line, null);
    }
}


alias configEnforce = enforce!(ConfigException);

