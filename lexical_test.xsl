<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:djb="http://www.obdurodon.org" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="#all" version="2.0">
    <xsl:output method="xml" indent="yes"/>
    <xsl:variable name="input" as="xs:string">что конЕчно слОн чАстный чтОбы скУчно</xsl:variable>
    <xsl:include href="lexical_inc.xsl"/>
    <xsl:template match="/">
        <root>
            <xsl:value-of select="djb:lexical($input)"/>
        </root>
    </xsl:template>
</xsl:stylesheet>
