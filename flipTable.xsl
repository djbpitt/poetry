<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns="http://www.w3.org/1999/xhtml"
    xpath-default-namespace="http://www.w3.org/1999/xhtml" exclude-result-prefixes="xs"
    version="2.0">
    <!-- Swaps rows and columns of HTML table -->
    <xsl:output method="xml" indent="yes" doctype-system="about:legacy-config"/>
    <xsl:variable name="root" as="document-node()" select="/"/>
    <xsl:template match="@* | node()">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="table">
        <table>
            <xsl:for-each select="1 to count(tr[1]/th)">
                <xsl:variable name="currentColNo" as="xs:integer" select="current()"/>
                <tr>
                    <xsl:for-each select="1 to count($root//tr[1]/th)">
                        <xsl:copy-of select="$root//tr[current()]/*[$currentColNo]"/>
                    </xsl:for-each>
                </tr>
            </xsl:for-each>
        </table>
    </xsl:template>
</xsl:stylesheet>
