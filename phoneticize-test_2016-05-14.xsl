<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:djb="http://www.obdurodon.org" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="#all" version="2.0">
    <!--
        Stage 1 : djb:prepareWords() : Flatten
            Convert stressed vowels to uppercase and remove stress tags
            Convert other text to lowercase
            Strip punctuation
            Normalize white space
        Stage 2 : djb:proclitics() : Merge proclitics and enclitics with bases
        
    -->
    <xsl:output method="xml" indent="yes"/>
    <xsl:variable name="poem" as="element(poem)">
        <poem>
            <line>"Мой д<stress>я</stress>дя с<stress>а</stress>мых ч<stress>е</stress>стных
                    пр<stress>а</stress>вил,</line>
            <line>Когд<stress>а</stress> не в ш<stress>у</stress>тку
                занем<stress>о</stress>г,</line>
            <line>Он уваж<stress>а</stress>ть себ<stress>я</stress> заст<stress>а</stress>вил</line>
            <line>И л<stress>у</stress>чше в<stress>ы</stress>думать не м<stress>о</stress>г.</line>
            <line>Ег<stress>о</stress> прим<stress>е</stress>р друг<stress>и</stress>м
                    на<stress>у</stress>ка;</line>
            <line>Но, б<stress>о</stress>же м<stress>о</stress>й, как<stress>а</stress>я
                    ск<stress>у</stress>ка</line>
            <line>С больн<stress>ы</stress>м сид<stress>е</stress>ть и д<stress>е</stress>нь и
                    н<stress>о</stress>чь,</line>
            <line>Не отход<stress>я</stress> ни ш<stress>а</stress>гу пр<stress>о</stress>чь!</line>
            <line>Как<stress>о</stress>е н<stress>и</stress>зкое ков<stress>а</stress>рство</line>
            <line>Полу-жив<stress>о</stress>го забавл<stress>я</stress>ть,</line>
            <line>Ем<stress>у</stress> под<stress>у</stress>шки поправл<stress>я</stress>ть,</line>
            <line>Печ<stress>а</stress>льно поднос<stress>и</stress>ть
                лек<stress>а</stress>рство,</line>
            <line>Вздых<stress>а</stress>ть и д<stress>у</stress>мать про
                себ<stress>я</stress>:</line>
            <line>Когд<stress>а</stress> же ч<stress>о</stress>рт возьм<stress>ё</stress>т
                    теб<stress>я</stress>!"</line>
        </poem>
    </xsl:variable>
    <xsl:template match="/">
        <xsl:apply-templates select="$poem"/>
    </xsl:template>
    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="line">
        <xsl:variable name="operations" as="element()+">
            <djb:prepareWords/>
            <djb:proclitics/>
            <djb:signOff/>
        </xsl:variable>
        <line>
            <xsl:apply-templates select="$operations[1]" mode="operate">
                <xsl:with-param name="input" select="."/>
                <xsl:with-param name="remaining" select="remove($operations, 1)"/>
            </xsl:apply-templates>
        </line>
    </xsl:template>
    <!-- djb:prepareWords (1)
        Convert stressed vowels to uppercase and remove <stress> tags
        Lowercase everything else
        Strip punctuation
        Input is <line>, output is string, all subsequent operations are on strings
    -->
    <xsl:template match="djb:prepareWords" mode="operate">
        <xsl:param name="input" as="element(line)" required="yes"/>
        <xsl:param name="remaining" as="element()*"/>
        <xsl:variable name="withWhiteSpace" as="xs:string+">
            <xsl:apply-templates select="$input" mode="#current"/>
        </xsl:variable>
        <xsl:variable name="result" as="xs:string+"
            select="string-join($withWhiteSpace, '')"/>
        <xsl:apply-templates select="$remaining[1]" mode="#current">
            <xsl:with-param name="input" select="$result"/>
            <xsl:with-param name="remaining" select="remove($remaining, 1)"/>
        </xsl:apply-templates>
        <xsl:if test="empty($remaining)">
            <xsl:sequence select="$result"/>
        </xsl:if>
    </xsl:template>
    <xsl:template match="stress" mode="operate">
        <xsl:value-of select="upper-case(.)"/>
    </xsl:template>
    <xsl:template match="line/text()" mode="operate">
        <xsl:value-of select="replace(lower-case(.), '\p{P}', '')"/>
    </xsl:template>
    <!-- djb:tokenize
        Merge proclitics and enclitics with bases
    -->
    <xsl:include href="proclitic_inc.xsl"/>
    <xsl:template match="djb:proclitics" mode="operate">
        <xsl:param name="input" as="xs:string" required="yes"/>
        <xsl:param name="remaining" as="element()*"/>
        <xsl:variable name="result" select="djb:proclitic($input, 1)" as="xs:string+"/>
        <xsl:apply-templates select="$remaining[1]" mode="#current">
            <xsl:with-param name="input" select="$result"/>
            <xsl:with-param name="remaining" select="remove($remaining, 1)"/>
        </xsl:apply-templates>
        <xsl:if test="empty($remaining)">
            <xsl:sequence select="$result"/>
        </xsl:if>
    </xsl:template>
    <!-- djb:signOff (last)
        Signal end of operations
    -->
    <xsl:template match="djb:signOff" mode="operate">
        <xsl:param name="input" as="xs:string+" required="yes"/>
        <xsl:param name="remaining" as="element()*"/>
        <xsl:variable name="result" as="xs:string+" select="$input"/>
        <xsl:if test="empty($remaining)">
            <xsl:sequence select="$result"/>
        </xsl:if>
    </xsl:template>
</xsl:stylesheet>
