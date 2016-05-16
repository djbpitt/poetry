<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:djb="http://www.obdurodon.org" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="#all" version="2.0">
    <!--
        Filename: rhyme.xsl
        Developer: djb 2015-05-15
        Repo: http://github.com/djbpitt/poetry
        Synopsis:
            Adds rhyme scheme annotation and line numbers within stanza to XML input
            Identifies only exact rhyme; intended for postprocessing to identify inexact rhyme
            Normal input is XML document with <poem> -> <body> -> <stanza> -> <line>, where line has <stress> and text() nodes
            May also be run against itself to identify rhyme scheme in included $poem variable
        Dependencies (in same directory):
            proclitic_inc.xsl (which imports proclitics.xml from same directory)
            enclitic_inc.xsl (which imports enclitics.xml from same directory)
        Notes:
            Regex based on:
                http://akhmatova.obdurodon.org/resources.html
                http://dh.obdurodon.org/drupal/iterating-over-transformations-without-you-know-hitting-go-million-times
            Thanks to WP for the "visitor pattern" pointer            
        License: GNU AGPLv3

        Visitor pattern steps
        =====================
        djb:prepareWords() : Flatten
            Convert stressed vowels to uppercase and remove stress tags
            Convert other text to lowercase
            Strip punctuation
            Normalize white space
        djb:proclitics() : Merge proclitics with bases
        djb:enclitics() : Merge enclitics with bases
        djb:tsa() : Convert ть?ся$ to тса
        djb:palatalize() : Capitalize all palatalized consonants (including unpaired)
        djb:jot() : Normalize /j/
            Insert Й before softening vowels after vowels, hard or soft sign, and (except in anlaut) и
            Convert softening vowels to non-softening
            Strip hard and soft signs
        djb:romanize() : Romanize now that all information is represented by the segment
        djb:finalDevoice() : Devoice obstruents in auslaut
        djb:regressiveDevoice() : Regressive devoicing of obstruents and /v/
            /v/ is easier to handle if we do devoicing first
        djb:regressiveVoice() : Regressive voicing of obstruents, including /v/
        djb:palatalAssimilation() : Regressive palatalization (Wade, section 6, p. 9)
        djb:consonantCleanup() : c > ts, sč to šč, degeminate
        djb:vowelReducation() : unstressed non-high vowels are i after soft consonants and i < e, a < o after hard
        djb:stripSpaces() : remove all spaces
        djb:rhymeString() : extract rhyme string (last stressed vowel, all following, supporting C for open masculine)

        To do: ad hoc lexical modifications:
            Final -ogo/-ego (before stripping spaces), except:
                (ne)?mnogo, strogo, ubogo, razlogo, otlogo, pologo, segodnja
            Č > š: что(б?ы)?, конечн.*, нарочн.*, очечник.*, прачечн.*, скучно, яичниц.*, ильиничн.*, саввичн.*, никитичн.*
            Idiosyncrasies: solnc.*, zdravstvuj.*, čuvstv*, zvezdn.*, landšaft.*, pozdno, prazdnik.*, serdc.*, grustn.*,
                izvestn.*, lestn.*, mestn.*, okrestnost.*, častn.*, sčastliv.*
    -->
    <xsl:output method="xml" indent="yes"/>
    <xsl:variable name="poem" as="element(poem)">
        <poem>
            <meta>
                <author>Pushkin</author>
                <title>EO</title>
                <note>First two stanzas</note>
            </meta>
            <body>
                <stanza>
                    <line>"Мой д<stress>я</stress>дя с<stress>а</stress>мых ч<stress>е</stress>стных
                            пр<stress>а</stress>вил,</line>
                    <line>Когд<stress>а</stress> не в ш<stress>у</stress>тку
                        занем<stress>о</stress>г,</line>
                    <line>Он уваж<stress>а</stress>ть себ<stress>я</stress>
                        заст<stress>а</stress>вил</line>
                    <line>И л<stress>у</stress>чше в<stress>ы</stress>думать не
                        м<stress>о</stress>г.</line>
                    <line>Ег<stress>о</stress> прим<stress>е</stress>р друг<stress>и</stress>м
                            на<stress>у</stress>ка;</line>
                    <line>Но, б<stress>о</stress>же м<stress>о</stress>й, как<stress>а</stress>я
                            ск<stress>у</stress>ка</line>
                    <line>С больн<stress>ы</stress>м сид<stress>е</stress>ть и д<stress>е</stress>нь
                        и н<stress>о</stress>чь,</line>
                    <line>Не отход<stress>я</stress> ни ш<stress>а</stress>гу
                        пр<stress>о</stress>чь!</line>
                    <line>Как<stress>о</stress>е н<stress>и</stress>зкое
                        ков<stress>а</stress>рство</line>
                    <line>Полу-жив<stress>о</stress>го забавл<stress>я</stress>ть,</line>
                    <line>Ем<stress>у</stress> под<stress>у</stress>шки
                        поправл<stress>я</stress>ть,</line>
                    <line>Печ<stress>а</stress>льно поднос<stress>и</stress>ть
                        лек<stress>а</stress>рство,</line>
                    <line>Вздых<stress>а</stress>ть и д<stress>у</stress>мать про
                            себ<stress>я</stress>:</line>
                    <line>Когд<stress>а</stress> же ч<stress>о</stress>рт возьм<stress>ё</stress>т
                            теб<stress>я</stress>!"</line>
                </stanza>
                <stanza>
                    <line>Так д<stress>у</stress>мал молод<stress>о</stress>й
                        пов<stress>е</stress>са,</line>
                    <line>Лет<stress>я</stress> в пыл<stress>и</stress> на
                        почтов<stress>ы</stress>х,</line>
                    <line>Всев<stress>ы</stress>шней в<stress>о</stress>лею
                        Зев<stress>е</stress>са</line>
                    <line>Насл<stress>е</stress>дник вс<stress>е</stress>х сво<stress>и</stress>х
                            родн<stress>ы</stress>х.</line>
                    <line>Друзь<stress>я</stress> Людм<stress>и</stress>лы и
                        Русл<stress>а</stress>на!</line>
                    <line>С гер<stress>о</stress>ем моег<stress>о</stress>
                        ром<stress>а</stress>на</line>
                    <line>Без предисл<stress>о</stress>вий, с<stress>е</stress>й же
                            ч<stress>а</stress>с</line>
                    <line>Позв<stress>о</stress>льте познак<stress>о</stress>мить
                            в<stress>а</stress>с:</line>
                    <line>Он<stress>е</stress>гин, д<stress>о</stress>брый м<stress>о</stress>й
                            при<stress>я</stress>тель,</line>
                    <line>Род<stress>и</stress>лся на брег<stress>а</stress>х
                        Нев<stress>ы</stress>,</line>
                    <line>Где, м<stress>о</stress>жет б<stress>ы</stress>ть,
                        род<stress>и</stress>лись в<stress>ы</stress></line>
                    <line>Или блист<stress>а</stress>ли, м<stress>о</stress>й
                        чит<stress>а</stress>тель;</line>
                    <line>Там н<stress>е</stress>когда гул<stress>я</stress>л и
                        <stress>я</stress>:</line>
                    <line>Но вр<stress>е</stress>ден с<stress>е</stress>вер для
                            мен<stress>я</stress>.</line>
                </stanza>
            </body>
        </poem>
    </xsl:variable>
    <xsl:variable name="alphabet"
        select="tokenize('a b c d e f g h i j k l m n o p q r s t u v w x y z', ' ')"
        as="xs:string+"/>
    <xsl:variable name="genders" select="tokenize('m f d h', ' ')" as="xs:string+"/>
    <xsl:template match="/">
        <xsl:choose>
            <xsl:when test="tokenize(base-uri(), '/')[last()] eq 'rhyme.xsl'">
                <xsl:apply-templates select="$poem"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="poem">
        <xsl:apply-templates select="body"/>
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
        <djb:finalDevoice/>
        <djb:regressiveDevoice/>
        <djb:regressiveVoice/>
        <djb:palatalAssimilation/>
        <djb:consonantCleanup/>
        <djb:vowelReduction/>
        <djb:stripSpaces/>
        <djb:rhymeString/>
    </xsl:variable>
    <!-- Process stanzas here -->
    <xsl:template match="stanza">
        <stanza>
            <!-- Group lines by rhyme strings and assign alphabetic letters in order -->
            <xsl:variable name="processed" as="element(line)+">
                <xsl:apply-templates select="line"/>
            </xsl:variable>
            <xsl:variable name="outputLines" as="element(line)+">
                <xsl:for-each-group select="$processed" group-by="@rhymeString">
                    <xsl:variable name="offset" as="xs:integer" select="position()"/>
                    <xsl:variable name="posttonic" as="xs:string"
                        select="replace(current-grouping-key(), '[^aeiou]+', '')"/>
                    <xsl:variable name="gender" as="xs:string"
                        select="$genders[position() eq string-length($posttonic) + 1]"/>
                    <xsl:variable name="letter" as="xs:string"
                        select="$alphabet[position() eq $offset]"/>
                    <xsl:variable name="renderedLetter" as="xs:string">
                        <xsl:choose>
                            <xsl:when test="$gender eq 'm'">
                                <xsl:value-of select="$letter"/>
                            </xsl:when>
                            <xsl:when test="$gender eq 'f'">
                                <xsl:value-of select="upper-case($letter)"/>
                            </xsl:when>
                            <xsl:when test="$gender eq 'd'">
                                <xsl:value-of select="concat(upper-case($letter), '′')"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="concat(upper-case($letter), '′′')"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <xsl:for-each select="current-group()">
                        <line letter="{$renderedLetter}">
                            <xsl:apply-templates select="@* | node()"/>
                        </line>
                    </xsl:for-each>
                </xsl:for-each-group>
            </xsl:variable>
            <xsl:for-each select="$outputLines">
                <xsl:sort select="number(@position)"/>
                <xsl:copy-of select="."/>
            </xsl:for-each>
        </stanza>
    </xsl:template>
    <!-- Process lines here -->
    <xsl:template match="line">
        <!-- Get the rhyme string -->
        <xsl:variable name="rhymeString" as="xs:string">
            <xsl:apply-templates select="$operations[1]" mode="operate">
                <xsl:with-param name="input" select="."/>
                <xsl:with-param name="remaining" select="remove($operations, 1)"/>
            </xsl:apply-templates>
        </xsl:variable>
        <!-- Add line order and rhyme string to line -->
        <line position="{position()}" rhymeString="{$rhymeString}">
            <xsl:apply-templates/>
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
    <xsl:include href="proclitic_inc.xsl"/>
    <xsl:include href="enclitic_inc.xsl"/>
    <!-- all visitor elements except djb:prepareWords, which requires element (not string) input -->
    <xsl:template match="djb:*" mode="operate">
        <xsl:param name="input" as="xs:string" required="yes"/>
        <xsl:param name="remaining" as="element()*"/>
        <xsl:variable name="results" as="xs:string*">
            <xsl:choose>
                <!-- ******************************************* -->
                <!-- djb:proclitics: Merge proclitics with bases -->
                <!-- ******************************************* -->
                <xsl:when test="self::djb:proclitics">
                    <xsl:sequence select="djb:proclitic($input, 1)"/>
                </xsl:when>
                <!-- ******************************************* -->
                <!-- djb:enclitics: Merge enclitics with bases -->
                <!-- ******************************************* -->
                <xsl:when test="self::djb:enclitics">
                    <xsl:sequence select="djb:enclitic($input, 1)"/>
                </xsl:when>
                <!-- ******************************************* -->
                <!-- djb:tsa: Convert ть?ся$ to тса -->
                <!-- ******************************************* -->
                <xsl:when test="self::djb:tsa">
                    <xsl:sequence select="replace($input, 'ться$', 'тса')"/>
                </xsl:when>
                <!-- ******************************************* -->
                <!-- djb:palatalize: Capitalize all palatalized consonants (including unpaired) -->
                <!-- ******************************************* -->
                <xsl:when test="self::djb:palatalize">
                    <xsl:variable name="result1" as="xs:string+">
                        <xsl:analyze-string select="$input"
                            regex="([бвгдзклмнпрстфх])([яеиёюЯЕИЁЮь])">
                            <xsl:matching-substring>
                                <xsl:sequence
                                    select="concat(upper-case(regex-group(1)), regex-group(2))"/>
                            </xsl:matching-substring>
                            <xsl:non-matching-substring>
                                <xsl:sequence select="."/>
                            </xsl:non-matching-substring>
                        </xsl:analyze-string>
                    </xsl:variable>
                    <xsl:sequence select="translate(string-join($result1, ''), 'чйщ', 'ЧЙЩ')"/>
                </xsl:when>
                <!-- ******************************************* -->
                <!-- djb:jot() : Normalize /j/ -->
                <!-- ******************************************* -->
                <!--                
                    Insert Й before softening vowels after vowels, hard or soft sign, and (except in anlaut) и
                    Convert softening vowels to non-softening
                    Strip hard and soft signs
                -->
                <xsl:when test="self::djb:jot">
                    <!-- $result1 processes softening vowels after vowels and signs, but not in anlaut-->
                    <xsl:variable name="result1" as="xs:string+">
                        <xsl:analyze-string select="$input"
                            regex="([аэыоюяеиёюАЭЫОУЯЕИЁЮьъ])([яеиёюЯЕИЁЮ])">
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
                        <xsl:analyze-string select="string-join($result1, '')"
                            regex="( |^)([яеёюЯЕЁЮ])">
                            <xsl:matching-substring>
                                <xsl:value-of select="concat(regex-group(1), 'Й', regex-group(2))"/>
                            </xsl:matching-substring>
                            <xsl:non-matching-substring>
                                <xsl:value-of select="."/>
                            </xsl:non-matching-substring>
                        </xsl:analyze-string>
                    </xsl:variable>
                    <!-- $result3 conflates softening vowels into regular ones and strips hard and soft signs-->
                    <xsl:sequence
                        select="translate(string-join($result2, ''), 'яеиёюЯЕИЁЮьъ', 'аэыоуАЭЫОУ')"
                    />
                </xsl:when>
                <!-- ******************************************* -->
                <!-- djb:romanize: Romanize now that all information is encoded in the segment -->
                <!-- ******************************************* -->
                <xsl:when test="self::djb:romanize">
                    <xsl:sequence
                        select="replace(translate($input, 'абвгджзклмнопрстуфхцшыэАБВГДЖЗЙКЛМНОПРСТУФХЦЧШЩЫЭ', 'abvgdžzklmnoprstufxcšieABVGDŽZJKLMNOPRSTUFXCČŠQIE'), 'Q', 'ŠČ')"
                    />
                </xsl:when>
                <!-- ******************************************* -->
                <!-- djb:finalDevoice: Devoice obstruents in auslaut -->
                <!-- ******************************************* -->
                <xsl:when test="self::djb:finalDevoice">
                    <xsl:variable name="result1" as="xs:string+">
                        <xsl:analyze-string select="$input" regex="([bvgdžzBVGDZ])( |$)">
                            <xsl:matching-substring>
                                <xsl:value-of
                                    select="concat(translate(regex-group(1), 'bvgdžzBVGDZ', 'pfktšsPFKTS'), regex-group(2))"
                                />
                            </xsl:matching-substring>
                            <xsl:non-matching-substring>
                                <xsl:value-of select="."/>
                            </xsl:non-matching-substring>
                        </xsl:analyze-string>
                    </xsl:variable>
                    <xsl:sequence select="string-join($result1, '')"/>
                </xsl:when>
                <!-- ******************************************* -->
                <!-- djb:regressiveDevoice: Regressive devoicing of obstruents, including /v/ -->
                <!-- ******************************************* -->
                <xsl:when test="self::djb:regressiveDevoice">
                    <xsl:variable name="result1" as="xs:string+">
                        <xsl:analyze-string select="$input"
                            regex="([bvgdžzBVGDZpfktšsPFKTSkcČ]+)([pfktšsPFKTSkcČ])">
                            <xsl:matching-substring>
                                <xsl:value-of
                                    select="concat(translate(regex-group(1), 'bvgdžzBVGDZ', 'pfktšsPFKTS'), regex-group(2))"
                                />
                            </xsl:matching-substring>
                            <xsl:non-matching-substring>
                                <xsl:value-of select="."/>
                            </xsl:non-matching-substring>
                        </xsl:analyze-string>
                    </xsl:variable>
                    <xsl:sequence select="string-join($result1, '')"/>
                </xsl:when>
                <!-- ******************************************* -->
                <!-- djb:regressiveVoice Regressive devoicing of obstruents, including /v/ -->
                <!-- ******************************************* -->
                <!-- 
                    ɣ (LC) = U+0263, Ɣ (UC) = U+0194
                    ʒ (LC) = U+0292, Ʒ (UC) = U+01B7
                    ǯ (LC) = U+01EF, Ǯ (UC) = U+01EE        
                -->
                <xsl:when test="self::djb:regressiveVoice">
                    <xsl:variable name="result1" as="xs:string+">
                        <xsl:analyze-string select="$input"
                            regex="([bvgdžzBVGDZpfktšsPFKTSkcČ]+)([bgdžzBGDZ])">
                            <xsl:matching-substring>
                                <xsl:value-of
                                    select="concat(translate(regex-group(1), 'pfktšsPFKTSxcČ', 'bvgdžzBVGDZɣʒǮ'), regex-group(2))"
                                />
                            </xsl:matching-substring>
                            <xsl:non-matching-substring>
                                <xsl:value-of select="."/>
                            </xsl:non-matching-substring>
                        </xsl:analyze-string>
                    </xsl:variable>
                    <xsl:sequence select="string-join($result1, '')"/>
                </xsl:when>
                <!-- ******************************************* -->
                <!-- djb:palatalAssimilation: Regressive palatalization assimilation -->
                <!-- ******************************************* -->
                <!-- šc has already been split, so requires special treatment -->
                <xsl:when test="self::djb:palatalAssimilation">
                    <xsl:variable name="result3" as="xs:string+">
                        <xsl:analyze-string select="$input" regex="[tdn]+[TDNSZČL]+">
                            <xsl:matching-substring>
                                <xsl:value-of select="upper-case(.)"/>
                            </xsl:matching-substring>
                            <xsl:non-matching-substring>
                                <xsl:value-of select="."/>
                            </xsl:non-matching-substring>
                        </xsl:analyze-string>
                    </xsl:variable>
                    <xsl:variable name="result2" as="xs:string+">
                        <xsl:analyze-string select="string-join($result3, '')"
                            regex="[tdnTDNSZČL]+ŠČ">
                            <xsl:matching-substring>
                                <xsl:value-of select="upper-case(.)"/>
                            </xsl:matching-substring>
                            <xsl:non-matching-substring>
                                <xsl:value-of select="."/>
                            </xsl:non-matching-substring>
                        </xsl:analyze-string>
                    </xsl:variable>
                    <xsl:variable name="result1" as="xs:string+">
                        <xsl:analyze-string select="string-join($result2, '')"
                            regex="[tdnsz]+[TDNSZL]+">
                            <xsl:matching-substring>
                                <xsl:value-of select="upper-case(.)"/>
                            </xsl:matching-substring>
                            <xsl:non-matching-substring>
                                <xsl:value-of select="."/>
                            </xsl:non-matching-substring>
                        </xsl:analyze-string>
                    </xsl:variable>
                    <xsl:sequence select="string-join($result1, '')"/>
                </xsl:when>
                <!-- ******************************************* -->
                <!-- djb:consonantCleanup() : c > ts, sč to šč, degeminate -->
                <!-- ******************************************* -->
                <xsl:when test="self::djb:consonantCleanup">
                    <xsl:variable name="result3" as="xs:string+">
                        <xsl:analyze-string select="$input" regex="c">
                            <xsl:matching-substring>
                                <xsl:text>ts</xsl:text>
                            </xsl:matching-substring>
                            <xsl:non-matching-substring>
                                <xsl:value-of select="."/>
                            </xsl:non-matching-substring>
                        </xsl:analyze-string>
                    </xsl:variable>
                    <xsl:variable name="result2" as="xs:string+">
                        <xsl:analyze-string select="string-join($result3, '')" regex="sČ">
                            <xsl:matching-substring>
                                <xsl:text>ŠČ</xsl:text>
                            </xsl:matching-substring>
                            <xsl:non-matching-substring>
                                <xsl:value-of select="."/>
                            </xsl:non-matching-substring>
                        </xsl:analyze-string>
                    </xsl:variable>
                    <xsl:variable name="result1" as="xs:string+">
                        <xsl:analyze-string select="$result2" regex="(.)\1">
                            <xsl:matching-substring>
                                <xsl:value-of select="regex-group(1)"/>
                            </xsl:matching-substring>
                            <xsl:non-matching-substring>
                                <xsl:value-of select="."/>
                            </xsl:non-matching-substring>
                        </xsl:analyze-string>
                    </xsl:variable>
                    <xsl:sequence select="string-join($result1, '')"/>
                </xsl:when>
                <!-- ******************************************* -->
                <!-- djb:vowelReduction() : unstressed non-high vowels are i after soft consonants and i < e, a < o after hard -->
                <!-- ******************************************* -->
                <xsl:when test="self::djb:vowelReduction">
                    <xsl:variable name="result1" as="xs:string+">
                        <xsl:analyze-string select="$input" regex="([BVGDJZKLMNPRSTFXČ])([eao])">
                            <xsl:matching-substring>
                                <xsl:value-of select="concat(regex-group(1), 'i')"/>
                            </xsl:matching-substring>
                            <xsl:non-matching-substring>
                                <xsl:value-of select="."/>
                            </xsl:non-matching-substring>
                        </xsl:analyze-string>
                    </xsl:variable>
                    <xsl:sequence select="translate(string-join($result1, ''), 'eo', 'ia')"/>
                </xsl:when>
                <!-- ******************************************* -->
                <!-- djb:stripSpaces() : strip all white space -->
                <!-- ******************************************* -->
                <xsl:when test="self::djb:stripSpaces">
                    <xsl:sequence select="translate($input, ' ', '')"/>
                </xsl:when>
                <!-- ******************************************* -->
                <!-- djb:rhymeString(): rhyme string is last stressed vowel, all following, supporting C for open masculine -->
                <!-- ******************************************* -->
                <xsl:when test="self::djb:rhymeString">
                    <xsl:variable name="result" as="xs:string">
                        <xsl:analyze-string select="$input" regex="(.)([AEIOU])([^AEIOU]*)$">
                            <xsl:matching-substring>
                                <xsl:value-of
                                    select="
                                        concat(if (regex-group(3) eq '') then
                                            regex-group(1)
                                        else
                                            (), regex-group(2), if (regex-group(3) ne '') then
                                            regex-group(3)
                                        else
                                            ())"
                                />
                            </xsl:matching-substring>
                        </xsl:analyze-string>
                    </xsl:variable>
                    <xsl:sequence select="$result"/>
                </xsl:when>
                <!-- ******************************************* -->
                <!-- Default to continue processing if operate step has no code-->
                <!-- ******************************************* -->
                <!--<xsl:otherwise>
                    <xsl:apply-templates select="$remaining[1]" mode="visit">
                        <xsl:with-param name="remainig" select="remove($remaining, 1)"/>
                        <xsl:with-param name="so-far" select="so-far"/>
                    </xsl:apply-templates>
                </xsl:otherwise>-->
                <!-- ******************************************* -->
                <!-- Default to terminate if operate step has no code-->
                <!-- ******************************************* -->
                <xsl:otherwise>
                    <xsl:message terminate="yes">Unmatched visitor element <xsl:value-of
                            select="local-name()"/></xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="result" as="xs:string" select="string-join($results, '')"/>
        <xsl:apply-templates select="$remaining[1]" mode="#current">
            <xsl:with-param name="input" select="$result"/>
            <xsl:with-param name="remaining" select="remove($remaining, 1)"/>
        </xsl:apply-templates>
        <xsl:if test="empty($remaining)">
            <xsl:sequence select="$result"/>
        </xsl:if>
    </xsl:template>
</xsl:stylesheet>
