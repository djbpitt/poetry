<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:djb="http://www.obdurodon.org" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="#all" version="2.0">
    <!--
        Filename: enclitic_inc.xsl
        Developer: djb 2015-05-14
        Repo: http://github.com/djbpitt/poetry
        Synopsis:
            Import to merge enclitics with preceding words in string sequence
            Call as djb:enclitic($input, 1)
        Dependency: imports enclitics.xml (from same directory)
        License: GNU AGPLv3
    -->
    <xsl:variable name="enclitics" select="document('enclitics.xml')//enclitic"
        as="element(enclitic)+"/>
    <xsl:function name="djb:enclitic" as="xs:string+">
        <xsl:param name="input" as="xs:string" required="yes"/>
        <xsl:param name="pos" as="xs:integer" required="yes"/>
        <xsl:variable name="tokenized" select="tokenize($input, '\s+')"/>
        <!-- Merge an enclitic with the preceding string -->
        <xsl:variable name="result" as="xs:string+">
            <xsl:choose>
                <xsl:when test="lower-case($tokenized[position() eq $pos]) = $enclitics">
                    <xsl:sequence select="$tokenized[position() lt $pos - 1]"/>
                    <xsl:sequence
                        select="concat($tokenized[position() eq $pos - 1], $tokenized[position() eq $pos])"/>
                    <xsl:sequence select="$tokenized[position() gt $pos]"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:sequence select="$tokenized"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <!-- increment $pos only if we haven't merged (determine from count); otherwise the merger increments automatically -->
        <xsl:variable name="newPos" as="xs:integer"
            select="
                if (count($tokenized) eq count($result)) then
                    $pos + 1
                else
                    $pos"/>
        <xsl:choose>
            <!-- Recurse until we run out of strings -->
            <xsl:when test="$pos lt count($result)">
                <xsl:sequence select="djb:enclitic(string-join($result, ' '), $newPos)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="string-join($result, ' ')"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
</xsl:stylesheet>
