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
        Stage 2 : djb:proclitics() : Merge proclitics with bases
        Stage 3 : djb:enclitics() : Merge enclitics with bases
        Stage 4 : djb:tsa() : Convert ть?ся$ to тса
        Stage 5 : djb:palatalize() : Capitalize all palatalized consonants (including unpaired)
        Stage 6 : djb:jot() : Normalize /j/
            Insert Й before softening vowels after vowels, hard or soft sign, and (except in anlaut) и
            Convert softening vowels to non-softening
            Strip hard and soft signs
        Stage 7 : djb:romanize() : Romanize now that all information is represented by the segment
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
    <!-- "Visitor" pattern; perform operations in this order -->
    <xsl:variable name="operations" as="element()+">
        <djb:prepareWords/>
        <djb:proclitics/>
        <djb:enclitics/>
        <djb:tsa/>
        <djb:palatalize/>
        <djb:jot/>
        <djb:romanize/>
        <djb:signOff/>
    </xsl:variable>
    <xsl:template match="line">
        <line>
            <xsl:apply-templates select="$operations[1]" mode="operate">
                <xsl:with-param name="input" select="."/>
                <xsl:with-param name="remaining" select="remove($operations, 1)"/>
            </xsl:apply-templates>
        </line>
    </xsl:template>
    <!-- djb:prepareWords
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
        <xsl:variable name="result" as="xs:string" select="string-join($withWhiteSpace, '')"/>
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
    <!-- djb:proclitics: Merge proclitics with bases -->
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
    <!-- djb:enclitics: Merge enclitics with bases -->
    <xsl:include href="enclitic_inc.xsl"/>
    <xsl:template match="djb:enclitics" mode="operate">
        <xsl:param name="input" as="xs:string" required="yes"/>
        <xsl:param name="remaining" as="element()*"/>
        <xsl:variable name="result" select="djb:enclitic($input, 1)" as="xs:string+"/>
        <xsl:apply-templates select="$remaining[1]" mode="#current">
            <xsl:with-param name="input" select="$result"/>
            <xsl:with-param name="remaining" select="remove($remaining, 1)"/>
        </xsl:apply-templates>
        <xsl:if test="empty($remaining)">
            <xsl:sequence select="$result"/>
        </xsl:if>
    </xsl:template>
    <!-- djb:tsa: Convert ть?ся$ to тса -->
    <xsl:template match="djb:tsa" mode="operate">
        <xsl:param name="input" as="xs:string" required="yes"/>
        <xsl:param name="remaining" as="element()*"/>
        <xsl:variable name="result" select="replace($input, 'ться$', 'тса')" as="xs:string+"/>
        <xsl:apply-templates select="$remaining[1]" mode="#current">
            <xsl:with-param name="input" select="$result"/>
            <xsl:with-param name="remaining" select="remove($remaining, 1)"/>
        </xsl:apply-templates>
        <xsl:if test="empty($remaining)">
            <xsl:sequence select="$result"/>
        </xsl:if>
    </xsl:template>
    <!-- djb:palatalize: Capitalize all palatalized consonants (including unpaired) -->
    <xsl:template match="djb:palatalize" mode="operate">
        <xsl:param name="input" as="xs:string" required="yes"/>
        <xsl:param name="remaining" as="element()*"/>
        <xsl:variable name="result1" as="xs:string+">
            <xsl:analyze-string select="$input" regex="([бвгдзклмнпрстфх])([яеиёюЯЕИЁЮь])">
                <xsl:matching-substring>
                    <xsl:sequence select="concat(upper-case(regex-group(1)), regex-group(2))"/>
                </xsl:matching-substring>
                <xsl:non-matching-substring>
                    <xsl:sequence select="."/>
                </xsl:non-matching-substring>
            </xsl:analyze-string>
        </xsl:variable>
        <xsl:variable name="result" as="xs:string"
            select="translate(string-join($result1, ''), 'чйщ', 'ЧЙЩ')"/>
        <xsl:apply-templates select="$remaining[1]" mode="#current">
            <xsl:with-param name="input" select="$result"/>
            <xsl:with-param name="remaining" select="remove($remaining, 1)"/>
        </xsl:apply-templates>
        <xsl:if test="empty($remaining)">
            <xsl:sequence select="$result"/>
        </xsl:if>
    </xsl:template>
    <!-- djb:jot() : Normalize /j/
        Insert Й before softening vowels after vowels, hard or soft sign, and (except in anlaut) и
        Convert softening vowels to non-softening
        Strip hard and soft signs
    -->
    <xsl:template match="djb:jot" mode="operate">
        <xsl:param name="input" as="xs:string" required="yes"/>
        <xsl:param name="remaining" as="element()*"/>
        <!-- $result1 processes softening vowels after vowels and signs, but not in anlaut-->
        <xsl:variable name="result1" as="xs:string+">
            <xsl:analyze-string select="$input" regex="([аэыоюяеиёюАЭЫОУЯЕИЁЮьъ])([яеиёюЯЕИЁЮ])">
                <xsl:matching-substring>
                    <xsl:value-of select="concat(regex-group(1), 'Й', regex-group(2))"/>
                </xsl:matching-substring>
                <xsl:non-matching-substring>
                    <xsl:value-of select="."/>
                </xsl:non-matching-substring>
            </xsl:analyze-string>
        </xsl:variable>
        <!-- $result2 processes softening vowels except и in anlaut-->
        <xsl:variable name="result2" as="xs:string+">
            <xsl:analyze-string select="string-join($result1, '')" regex="( |^)([яеёюЯЕЁЮ])">
                <xsl:matching-substring>
                    <xsl:value-of select="concat(regex-group(1), 'Й', regex-group(2))"/>
                </xsl:matching-substring>
                <xsl:non-matching-substring>
                    <xsl:value-of select="."/>
                </xsl:non-matching-substring>
            </xsl:analyze-string>
        </xsl:variable>
        <!-- $result3 conflates softening vowels into regular ones and strips hard and soft signs-->
        <xsl:variable name="result3" as="xs:string">
            <xsl:value-of
                select="translate(string-join($result2, ''), 'яеиёюЯЕИЁЮьъ', 'аэыоуАЭЫОУ')"/>
        </xsl:variable>
        <xsl:variable name="result" select="string-join($result3, '')" as="xs:string"/>
        <xsl:apply-templates select="$remaining[1]" mode="#current">
            <xsl:with-param name="input" select="$result"/>
            <xsl:with-param name="remaining" select="remove($remaining, 1)"/>
        </xsl:apply-templates>
        <xsl:if test="empty($remaining)">
            <xsl:sequence select="$result"/>
        </xsl:if>
    </xsl:template>
    <!-- djb:romanize: Romanize now that all information is encoded in the segment -->
    <xsl:template match="djb:romanize" mode="operate">
        <xsl:param name="input" as="xs:string" required="yes"/>
        <xsl:param name="remaining" as="element()*"/>
        <xsl:variable name="result"
            select="replace(translate($input, 'абвгджзклмнопрстуфхцшыэАБВГДЖЗЙКЛМНОПРСТУФХЦЧШЩЫЭ', 'abvgdžzklmnoprstufxcšieABVGDŽZJKLMNOPRSTUFXCČŠQIE'), 'Q', 'šČ')"
            as="xs:string"/>
        <xsl:apply-templates select="$remaining[1]" mode="#current">
            <xsl:with-param name="input" select="$result"/>
            <xsl:with-param name="remaining" select="remove($remaining, 1)"/>
        </xsl:apply-templates>
        <xsl:if test="empty($remaining)">
            <xsl:sequence select="$result"/>
        </xsl:if>
    </xsl:template>
    <!-- djb:signOff (last): Signal end of operations -->
    <xsl:template match="djb:signOff" mode="operate">
        <xsl:param name="input" as="xs:string+" required="yes"/>
        <xsl:param name="remaining" as="element()*"/>
        <xsl:variable name="result" as="xs:string+" select="$input"/>
        <xsl:if test="empty($remaining)">
            <xsl:sequence select="$result"/>
        </xsl:if>
    </xsl:template>
</xsl:stylesheet>
