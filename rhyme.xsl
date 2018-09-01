<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:html="http://www.w3.org/1999/xhtml" xmlns:djb="http://www.obdurodon.org"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all" version="2.0">
    <!--
        Filename: rhyme.xsl
        Developer: David J. Birnbaum 2015-05-15 (see GitHub repo for commit history)
        Repo: http://github.com/djbpitt/poetry
        Synopsis:
            Adds rhyme scheme annotation and line numbers within stanza to XML input
            Identifies only exact rhyme; intended for postprocessing to identify inexact rhyme
            Normal input is XML document with <poem> -> <body> -> <stanza> -> <line>, where line has <stress> and text() nodes
            May also be run against itself to identify rhyme scheme in included $poem variable
        Dependencies (in same directory):
            proclitic_inc.xsl (which imports proclitics.xml from same directory)
            enclitic_inc.xsl (which imports enclitics.xml from same directory)
            lexical_inc.xsl (which imports lexical.xml from same directory)
        Notes:
            Regex based on:
                http://akhmatova.obdurodon.org/resources.html
                http://dh.obdurodon.org/drupal/iterating-over-transformations-without-you-know-hitting-go-million-times
                    (requires authentication)
            Thanks to Wendell Piez for the "visitor pattern" pointer            
        License: GNU AGPLv3

        Visitor pattern steps
        =========================================
        djb:prepareWords() : Flatten
            Convert stressed vowels to uppercase and remove stress tags
            Convert other text to lowercase
            Strip punctuation
            Normalize white space
        djb:lexical(): Correct for -ого and lexical idiosyncrasies (e.g., солнце)
            Final -ogo/-ego (before stripping spaces), except:
                (ne)?mnogo, strogo, ubogo, razlogo, otlogo, pologo, segodnja
            Č > š: что(б?ы)?, конечн.*, нарочн.*, очечник.*, прачечн.*, скучно, яичниц.*, ильиничн.*, саввичн.*, никитичн.*
            Idiosyncrasies: solnc.*, zdravstvuj.*, čuvstv*, zvezdn.*, landšaft.*, pozdno, prazdnik.*, serdc.*, grustn.*,
                izvestn.*, lestn.*, mestn.*, okrestnost.*, častn.*, sčastliv.*
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
    -->
    <xsl:output method="xml" indent="yes"/>
    <!-- ======================================== -->
    <!-- 
        Create bitstring for rhyming segment; return rhyming vowel and full bitstring 
    -->
    <!-- ======================================== -->
    <xsl:variable name="featureFile" as="document-node()" select="document('feature-chart.xhtml')"/>
    <xsl:key name="bitStringBySegment" match="html:tr" use="html:th"/>
    <xsl:function name="djb:bits" as="xs:string+">
        <xsl:param name="input" as="xs:string"/>
        <xsl:variable name="stressedVowel" as="xs:string" select="replace($input, '[^AEIOU]', '')"/>
        <xsl:variable name="rhymeVowelBitString" as="xs:string"
            select="string-join(key('bitStringBySegment', $stressedVowel, $featureFile)/html:td, '')"/>
        <xsl:variable name="bitStrings" as="xs:string+">
            <!-- bitstring for full rhyme -->
            <xsl:for-each
                select="
                    for $char in string-to-codepoints($input)
                    return
                        codepoints-to-string($char)">
                <xsl:value-of
                    select="string-join(key('bitStringBySegment', ., $featureFile)/html:td, '')"/>
            </xsl:for-each>
        </xsl:variable>
        <xsl:sequence select="($rhymeVowelBitString, string-join($bitStrings, ''))"/>
    </xsl:function>
    <!-- ======================================== -->

    <!-- ======================================== -->
    <!-- djb:findInexact(lines as element(line)+) as element(line)+ -->
    <!-- ======================================== -->
    <xsl:function name="djb:findInexact" as="element(line)+">
        <xsl:param name="inputLines"/>
        <xsl:param name="offset" as="xs:integer"/>
        <xsl:choose>
            <xsl:when test="$offset gt count($inputLines)">
                <!-- all lines have been processed -->
                <xsl:sequence select="$inputLines"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="allLetters" as="xs:string+" select="$inputLines/@letter"/>
                <xsl:variable name="unmatched_letters" as="xs:string*"
                    select="$allLetters[count(index-of($allLetters, .)) eq 1]"/>
                <xsl:variable name="currentLine" as="element(line)" select="$inputLines[$offset]"/>
                <xsl:choose>
                    <xsl:when test="not($currentLine/@letter = $unmatched_letters)">
                        <!-- $currentLine has a rhyme already -->
                        <xsl:sequence select="djb:findInexact($inputLines, $offset + 1)"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <!-- domain is three preceding lines (not following, since we'll get to those later -->
                        <xsl:variable name="domain" as="element(line)*"
                            select="$inputLines[position() gt $offset - 4 and position() lt $offset and @letter = $unmatched_letters]"/>
                        <xsl:choose>
                            <!-- if there is a preceding stressed vowel match, the closest one is the rhyme -->
                            <xsl:when test="$currentLine/@vowelBitString = $domain/@vowelBitString">
                                <xsl:variable name="precedingRhymingLine" as="element(line)"
                                    select="$domain[@vowelBitString = $currentLine/@vowelBitString][1]"/>
                                <xsl:variable name="newRhymeLetter" as="xs:string"
                                    select="$precedingRhymingLine/@letter"/>
                                <xsl:variable name="rerhymedLine" as="element(line)">
                                    <line>
                                        <xsl:sequence
                                            select="$currentLine/@* except $currentLine/@letter"/>
                                        <xsl:attribute name="letter" select="$newRhymeLetter"/>
                                        <xsl:sequence select="$currentLine/node()"/>
                                    </line>
                                </xsl:variable>
                                <xsl:variable name="updatedInput" as="element(line)+">
                                    <xsl:sequence select="$inputLines[position() lt $offset]"/>
                                    <xsl:sequence select="$rerhymedLine"/>
                                    <xsl:sequence select="$inputLines[position() gt $offset]"/>
                                </xsl:variable>
                                <xsl:sequence select="djb:findInexact($updatedInput, $offset + 2)"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <!-- no rhyme; return line as is -->
                                <xsl:sequence select="djb:findInexact($inputLines, $offset + 1)"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- ======================================== -->


    <!-- ======================================== -->
    <!-- Sample poem, used when stylesheet is run against itself -->
    <!-- ======================================== -->
    <xsl:variable name="poem" as="document-node()" select="doc('eo.xml')"/>
    <!-- ======================================== -->

    <!-- ======================================== -->
    <!-- Variables used for rhyme scheme ($alphabet) and rhyme gender ($gender) -->
    <!-- ======================================== -->
    <xsl:variable name="alphabet"
        select="tokenize('a b c d e f g h i j k l m n o p q r s t u v w x y z', ' ')"
        as="xs:string+"/>
    <xsl:variable name="genders" select="tokenize('m f d h1 h2 h3', ' ')" as="xs:string+"/>
    <!-- ======================================== -->

    <!-- ======================================== -->
    <!-- Build table of rhymes by stressed vowel (used to resolve imperfect rhyme) -->
    <!-- ======================================== -->
    <xsl:key name="lineByStressedVowel" match="line" use="@vowelBitString"/>
    <!-- ======================================== -->

    <!-- ======================================== -->
    <!-- Process <poem> element (external or embedded); identity template -->
    <!-- ======================================== -->
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
        <xsl:copy>
            <xsl:copy-of select="meta"/>
            <xsl:apply-templates select="body"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*"/>
        </xsl:copy>
    </xsl:template>
    <!-- ======================================== -->

    <!-- ======================================== -->
    <!-- "Visitor" pattern; perform operations in this order -->
    <!-- ======================================== -->
    <xsl:variable name="operations" as="element()+">
        <djb:prepareWords/>
        <djb:lexical/>
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
        <!-- 
            diagnosticOutput writes the string to stderr as an <xsl:message>
            move it around or comment it out, as appropriate
        -->
        <!--<djb:diagnosticOutput/>-->
        <djb:stripSpaces/>
        <djb:rhymeString/>
    </xsl:variable>
    <!-- ======================================== -->

    <!-- ======================================== -->
    <!-- Process stanzas here -->
    <!-- ======================================== -->
    <xsl:template match="stanza">
        <xsl:variable name="lines_with_exact_rhyme" as="document-node()">
            <!-- Make it a document so that we can use a key -->
            <xsl:document>
                <stanza>
                    <!-- ======================================== -->
                    <!-- Process lines phonetically before determining rhyme scheme -->
                    <!-- ======================================== -->
                    <xsl:variable name="processed" as="element(line)+">
                        <xsl:apply-templates select="line"/>
                    </xsl:variable>
                    <!-- ======================================== -->
                    <!-- Group lines by rhyme and create rhyme scheme -->
                    <!-- ======================================== -->
                    <xsl:variable name="outputLines" as="element(line)+">
                        <xsl:for-each-group select="$processed" group-by="@rhymeString">
                            <xsl:variable name="offset" as="xs:integer" select="position()"/>
                            <xsl:variable name="posttonic" as="xs:string"
                                select="replace(current-grouping-key(), '[^aeiou]+', '')"/>
                            <xsl:variable name="gender" as="xs:string"
                                select="$genders[position() eq string-length($posttonic) + 1]"/>
                            <xsl:variable name="letter" as="xs:string"
                                select="
                                    $alphabet[position() eq (if ($offset mod 26 eq 0) then
                                        26
                                    else
                                        $offset mod 26)]"/>
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
            </xsl:document>
        </xsl:variable>
        <!-- ======================================== -->
        <!--
            By this stage $stanza_with_exact_rhyme includes all exact rhymes
            Now process for inexact
        -->
        <!-- ======================================== -->

        <!-- ======================================== -->
        <!-- Now process lines -->
        <!-- ======================================== -->
        <xsl:apply-templates select="$lines_with_exact_rhyme" mode="inexact"/>
    </xsl:template>
    <!-- ======================================== -->

    <!-- ======================================== -->
    <!-- First fine exact rhymes (no mode) -->
    <!-- ======================================== -->
    <!-- Process original input lines here -->
    <!-- ======================================== -->
    <xsl:template match="line">
        <!-- ======================================== -->
        <!-- The visitor tour gets the rhyme string -->
        <!-- ======================================== -->
        <xsl:variable name="rhymeString" as="xs:string">
            <xsl:apply-templates select="$operations[1]" mode="operate">
                <xsl:with-param name="input" select="."/>
                <xsl:with-param name="remaining" select="remove($operations, 1)"/>
            </xsl:apply-templates>
        </xsl:variable>
        <!-- ======================================== -->
        <!-- Add line order, rhyme string, and bitstring to line -->
        <!-- ======================================== -->
        <xsl:variable name="bitStrings" as="xs:string+" select="djb:bits($rhymeString)"/>
        <line position="{position()}" rhymeString="{$rhymeString}" vowelBitString="{$bitStrings[1]}"
            bitString="{$bitStrings[2]}">
            <xsl:apply-templates/>
        </line>
    </xsl:template>
    <xsl:template match="line/text()">
        <xsl:value-of select="replace(., '\s+', ' ')"/>
    </xsl:template>
    <!-- ======================================== -->

    <!-- ======================================== -->
    <!-- djb:prepareWords
        Convert stressed vowels to uppercase and remove <stress> tags
        Lowercase everything else
        Strip punctuation
        Input is <line>, output is string, all subsequent operations are on strings
        This is the only visitor pattern not included in the general rule below
            because it takes element(line) input
    -->
    <!-- ======================================== -->
    <xsl:template match="djb:prepareWords" mode="operate">
        <xsl:param name="input" as="element(line)" required="yes"/>
        <xsl:param name="remaining" as="element()*"/>
        <xsl:variable name="withWhiteSpace" as="xs:string+">
            <!-- uppercase stressed vowel, lowercase other letters, strip punctuation -->
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
    <!-- ======================================== -->

    <!-- ======================================== -->
    <!-- Include external functions -->
    <!-- ======================================== -->
    <xsl:include href="proclitic_inc.xsl"/>
    <xsl:include href="enclitic_inc.xsl"/>
    <xsl:include href="lexical_inc.xsl"/>
    <!-- ======================================== -->

    <!-- ======================================== -->
    <!-- all visitor elements except djb:prepareWords (above), which requires element (not string) input -->
    <!-- ======================================== -->
    <xsl:template match="djb:*" mode="operate">
        <xsl:param name="input" as="xs:string" required="yes"/>
        <xsl:param name="remaining" as="element()*"/>
        <xsl:variable name="results" as="xs:string*">
            <xsl:choose>
                <!-- ======================================== -->
                <!-- djb:lexical: Idiosyncrasies in pronunciation (including -ogo) -->
                <!-- ======================================== -->
                <xsl:when test="self::djb:lexical">
                    <xsl:sequence select="djb:lexical($input)"/>
                </xsl:when>
                <!-- ======================================== -->
                <!-- djb:proclitics: Merge proclitics with bases -->
                <!-- ======================================== -->
                <xsl:when test="self::djb:proclitics">
                    <xsl:sequence select="djb:proclitic($input, 1)"/>
                </xsl:when>
                <!-- ======================================== -->
                <!-- djb:enclitics: Merge enclitics with bases -->
                <!-- ======================================== -->
                <xsl:when test="self::djb:enclitics">
                    <xsl:sequence select="djb:enclitic($input, 1)"/>
                </xsl:when>
                <!-- ======================================== -->
                <!-- djb:tsa: Convert ть?ся$ to тса -->
                <!-- ======================================== -->
                <xsl:when test="self::djb:tsa">
                    <xsl:sequence select="replace($input, 'ться$', 'тса')"/>
                </xsl:when>
                <!-- ======================================== -->
                <!-- djb:palatalize: Capitalize all palatalized consonants (including unpaired) -->
                <!-- ======================================== -->
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
                <!-- ======================================== -->
                <!-- djb:jot() : Normalize /j/ -->
                <!-- ======================================== -->
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
                <!-- ======================================== -->
                <!-- djb:romanize: Romanize now that all information is encoded in the segment -->
                <!-- ======================================== -->
                <xsl:when test="self::djb:romanize">
                    <xsl:sequence
                        select="replace(translate($input, 'абвгджзклмнопрстуфхцшыэАБВГДЖЗЙКЛМНОПРСТУФХЦЧШЩЫЭ', 'abvgdžzklmnoprstufxcšieABVGDŽZJKLMNOPRSTUFXCČŠQIE'), 'Q', 'ŠČ')"
                    />
                </xsl:when>
                <!-- ======================================== -->
                <!-- djb:finalDevoice: Devoice obstruents in auslaut -->
                <!-- ======================================== -->
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
                <!-- ======================================== -->
                <!-- djb:regressiveDevoice: Regressive devoicing of obstruents, including /v/ -->
                <!-- ======================================== -->
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
                <!-- ======================================== -->
                <!-- djb:regressiveVoice Regressive voicing of obstruents, but not before /v/ -->
                <!-- ======================================== -->
                <!-- 
                    ɣ (LC) = U+0263, Ɣ (UC) = U+0194
                    ʒ (LC) = U+0292, Ʒ (UC) = U+01B7
                    ǯ (LC) = U+01EF, Ǯ (UC) = U+01EE        
                -->
                <xsl:when test="self::djb:regressiveVoice">
                    <xsl:variable name="result1" as="xs:string+">
                        <xsl:analyze-string select="$input"
                            regex="([bvgdžzBVGDZpfktšsPFKTSxcČ]+)([bgdžzBGDZ])">
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
                <!-- ======================================== -->
                <!-- djb:palatalAssimilation: Regressive palatalization assimilation -->
                <!-- ======================================== -->
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
                <!-- ======================================== -->
                <!-- djb:consonantCleanup() : c > ts, sČ to ŠČ, degeminate -->
                <!-- ======================================== -->
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
                        <xsl:analyze-string select="string-join($result2, '')" regex="(.)\1">
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
                <!-- ======================================== -->
                <!-- djb:vowelReduction() : unstressed non-high vowels > i after soft consonants and e > i, o > a after hard -->
                <!-- ======================================== -->
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
                <!-- ======================================== -->
                <!-- djb:diagnosticOutput() : write string to stderr as <xsl:message> -->
                <!-- ======================================== -->
                <xsl:when test="self::djb:diagnosticOutput">
                    <xsl:message>
                        <xsl:sequence select="$input"/>
                    </xsl:message>
                    <xsl:sequence select="$input"/>
                </xsl:when>
                <!-- ======================================== -->
                <!-- djb:stripSpaces() : strip all white space -->
                <!-- ======================================== -->
                <xsl:when test="self::djb:stripSpaces">
                    <xsl:sequence select="translate($input, ' ', '')"/>
                </xsl:when>
                <!-- ======================================== -->
                <!-- djb:rhymeString(): last stressed vowel, all following, supporting C for open masculine -->
                <!-- ======================================== -->
                <xsl:when test="self::djb:rhymeString">
                    <xsl:variable name="result" as="xs:string">
                        <xsl:analyze-string select="$input" regex="(.)([AEIOU])([^AEIOU]*)$">
                            <xsl:matching-substring>
                                <xsl:value-of
                                    select="
                                        concat(if (regex-group(3) eq '')
                                        then
                                            regex-group(1)
                                        else
                                            (),
                                        regex-group(2),
                                        regex-group(3))"
                                />
                            </xsl:matching-substring>
                        </xsl:analyze-string>
                    </xsl:variable>
                    <xsl:sequence select="$result"/>
                </xsl:when>
                <!-- ======================================== -->
                <!-- Default to continue processing if operate step has no code -->
                <!-- ======================================== -->
                <!--<xsl:otherwise>
                    <xsl:apply-templates select="$remaining[1]" mode="visit">
                        <xsl:with-param name="remaining" select="remove($remaining, 1)"/>
                        <xsl:with-param name="so-far" select="so-far"/>
                    </xsl:apply-templates>
                </xsl:otherwise>-->
                <!-- ======================================== -->
                <!-- Default to terminate if operate step has no code -->
                <!-- ======================================== -->
                <xsl:otherwise>
                    <xsl:message terminate="yes">Unmatched visitor element <xsl:value-of
                            select="local-name()"/></xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="result" as="xs:string" select="string-join($results, '')"/>
        <!-- ======================================== -->
        <!-- Move on to the next step or return if done -->
        <!-- ======================================== -->
        <xsl:apply-templates select="$remaining[1]" mode="#current">
            <xsl:with-param name="input" select="$result"/>
            <xsl:with-param name="remaining" select="remove($remaining, 1)"/>
        </xsl:apply-templates>
        <xsl:if test="empty($remaining)">
            <xsl:sequence select="$result"/>
        </xsl:if>
    </xsl:template>
    <!-- ======================================== -->
    <!-- Process inexact rhyme (mode="inexact") -->
    <!-- ======================================== -->
    <xsl:template match="node() | @*" mode="inexact">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="stanza" mode="inexact">
        <xsl:variable name="allLines" as="element(line)+">
            <xsl:sequence select="line"/>
        </xsl:variable>
        <stanza>
            <xsl:sequence select="djb:findInexact($allLines, 1)"/>
        </stanza>
    </xsl:template>
</xsl:stylesheet>
