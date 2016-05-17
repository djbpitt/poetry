<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:djb="http://www.obdurodon.org" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="#all" version="2.0">
    <!--
        Filename: lexical_inc.xsl
        Developer: djb 2015-05-16
        Repo: http://github.com/djbpitt/poetry
        Synopsis:
            Import to adjust spelling of lexical pronunciation exceptions
            Call as djb:lexical($input)
        Dependency: lexical.xml (in same directory)
        License: GNU AGPLv3
    -->
    <xsl:function name="djb:replaceOrths" as="xs:string">
        <xsl:param name="input" as="xs:string"/>
        <xsl:param name="offset" as="xs:integer"/>
        <xsl:choose>
            <xsl:when test="$offset le count($orths)">
                <xsl:value-of
                    select="djb:replaceOrths(replace($input, $orths[$offset], key('pairByOrth', $orths[$offset], $lexicalPairsDoc)/phon), $offset + 1)"
                />
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="$input"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    <xsl:variable name="lexicalPairsDoc" as="document-node()" select="document('lexical.xml')"/>
    <xsl:variable name="orths" as="xs:string+" select="$lexicalPairsDoc//orth"/>
    <xsl:variable name="orthRegex" as="xs:string"
        select="concat('(', string-join($orths, '|'), ')')"/>
    <xsl:key name="pairByOrth" match="pair" use="orth"/>
    <xsl:function name="djb:lexical" as="xs:string+">
        <xsl:param name="input" as="xs:string" required="yes"/>
        <xsl:variable name="tokenized" select="tokenize($input, '\s+')"/>
        <xsl:variable name="results" as="xs:string+">
            <xsl:for-each select="$tokenized">
                <xsl:choose>
                    <xsl:when test="matches(., $orthRegex)">
                        <xsl:sequence select="djb:replaceOrths(., 1)"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:sequence select="."/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
        </xsl:variable>
        <xsl:sequence select="$results"/>
    </xsl:function>
</xsl:stylesheet>
