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
        History:
            2016-05-16 First version
            2016-09-01 Expanded documentation
        
        Ad hoc pairs are imported from lexical.xml
        -ogo/-ego are handled separately by djb:ogo(), after using $ogoExceptions to exclude false positives
    -->
    <xsl:function name="djb:replaceOrths" as="xs:string">
        <!-- Execute all pairwise replacements in lexical.xml file -->
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
    <xsl:function name="djb:ogo" as="xs:string">
        <xsl:param name="input" as="xs:string"/>
        <xsl:variable name="result" as="xs:string">
            <xsl:choose>
                <xsl:when test="$input = $ogoExceptions">
                    <xsl:value-of select="$input"/>
                </xsl:when>
                <xsl:when test="$input eq 'сегОдня'">
                    <xsl:text>севОдня</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="replace($input, '([оОеЕ])г([оО])$', '$1в$2')"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:sequence select="$result"/>
    </xsl:function>
    <!-- Variables and keys -->
    <xsl:variable name="lexicalPairsDoc" as="document-node()" select="document('lexical.xml')"/>
    <xsl:variable name="orths" as="xs:string+" select="$lexicalPairsDoc//orth"/>
    <xsl:variable name="orthRegex" as="xs:string"
        select="concat('(', string-join($orths, '|'), ')')"/>
    <xsl:key name="pairByOrth" match="pair" use="orth"/>
    <xsl:variable name="ogoExceptions" as="xs:string+"
        select="tokenize('немнОго мнОго стрОго убОго разлОго отлОго полОго', ' ')"/>
    <!-- lexical() : processes idiosyncratic lexical exceptions -->
    <xsl:function name="djb:lexical" as="xs:string+">
        <xsl:param name="input" as="xs:string"/>
        <xsl:variable name="tokenized" select="tokenize($input, '\s+')"/>
        <xsl:variable name="results" as="xs:string+">
            <xsl:for-each select="$tokenized">
                <xsl:choose>
                    <xsl:when test="matches(., $orthRegex)">
                        <xsl:sequence select="djb:replaceOrths(djb:ogo(.), 1)"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:sequence select="djb:ogo(.)"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
        </xsl:variable>
        <xsl:sequence select="string-join($results, ' ')"/>
    </xsl:function>
</xsl:stylesheet>
