<xsl:stylesheet version = '1.0'
     xmlns:xsl='http://www.w3.org/1999/XSL/Transform'
     >

<xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"
 doctype-public="-//OASIS//DTD DocBook XML V4.3//EN"
 doctype-system="/usr/share/sgml/docbook/xml-dtd-4.3/docbookx.dtd"
 />

<xsl:template match="/">
        <xsl:apply-templates select="//body" />  
</xsl:template>

<xsl:template match="body">
    <article>
        <xsl:attribute name="id">
            <xsl:value-of select="@id" />
        </xsl:attribute>
        <xsl:apply-templates select="scene" />
    </article>
</xsl:template>

<xsl:template match="scene">
    <section>
        <xsl:attribute name="id">
            <xsl:value-of select="@id" />
        </xsl:attribute>
        <title>
            <xsl:value-of select="@id" />
        </title>
        <xsl:apply-templates select="scene|description|saying" />
    </section>
</xsl:template>

<xsl:template match="description">
    <section role="description" id="{generate-id()}">
        <title></title>
            <xsl:apply-templates />
    </section>
</xsl:template>

<xsl:template match="saying">
    <section role="saying" id="{generate-id()}">
        <title></title>
        <xsl:apply-templates />
    </section>
</xsl:template>

<xsl:template match="para">
    <para>
        <xsl:if test="local-name(..) = 'saying'">
            <emphasis role="bold"><xsl:value-of select="../@character" />: </emphasis>
        </xsl:if>
        <xsl:if test="local-name(..) = 'description' and ../child::para[position()=1] = .">
            [
        </xsl:if>
        <xsl:apply-templates />
        <xsl:if test="local-name(..) = 'description' and ../child::para[position()=last()] = .">
            ]
        </xsl:if>
    </para>
</xsl:template>

<xsl:template match="ulink">
    <ulink>
        <xsl:attribute name="url">
            <xsl:value-of select="@url" />
        </xsl:attribute>
    </ulink>
</xsl:template>

<xsl:template match="bold">
    <emphasis role="bold">
        <xsl:apply-templates />
    </emphasis>
</xsl:template>

<xsl:template match="inlinedesc">
    <phrase>[<xsl:apply-templates />]</phrase>
</xsl:template>

</xsl:stylesheet>
