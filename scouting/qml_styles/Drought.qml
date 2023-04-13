<!DOCTYPE qgis PUBLIC 'http://mrcc.com/qgis.dtd' 'SYSTEM'>
<qgis styleCategories="AllStyleCategories" minScale="1e+08" version="3.22.7-Białowieża" hasScaleBasedVisibilityFlag="0" maxScale="0">
  <flags>
    <Identifiable>1</Identifiable>
    <Removable>1</Removable>
    <Searchable>1</Searchable>
    <Private>0</Private>
  </flags>
  <temporal enabled="0" fetchMode="0" mode="0">
    <fixedRange>
      <start></start>
      <end></end>
    </fixedRange>
  </temporal>
  <customproperties>
    <Option type="Map">
      <Option name="WMSBackgroundLayer" type="bool" value="false"/>
      <Option name="WMSPublishDataSourceUrl" type="bool" value="false"/>
      <Option name="embeddedWidgets/count" type="int" value="0"/>
      <Option name="identify/format" type="QString" value="Value"/>
    </Option>
  </customproperties>
  <pipe-data-defined-properties>
    <Option type="Map">
      <Option name="name" type="QString" value=""/>
      <Option name="properties"/>
      <Option name="type" type="QString" value="collection"/>
    </Option>
  </pipe-data-defined-properties>
  <pipe>
    <provider>
      <resampling zoomedInResamplingMethod="nearestNeighbour" enabled="false" maxOversampling="2" zoomedOutResamplingMethod="nearestNeighbour"/>
    </provider>
    <rasterrenderer alphaBand="-1" nodataColor="" band="1" opacity="1" type="paletted">
      <rasterTransparency/>
      <minMaxOrigin>
        <limits>None</limits>
        <extent>WholeRaster</extent>
        <statAccuracy>Estimated</statAccuracy>
        <cumulativeCutLower>0.02</cumulativeCutLower>
        <cumulativeCutUpper>0.98</cumulativeCutUpper>
        <stdDevFactor>2</stdDevFactor>
      </minMaxOrigin>
      <colorPalette>
        <paletteEntry alpha="255" label="-3.75" value="-3.75" color="#d7191c"/>
        <paletteEntry alpha="255" label="-3.25" value="-3.25" color="#e1412e"/>
        <paletteEntry alpha="255" label="-2.75" value="-2.75" color="#eb6841"/>
        <paletteEntry alpha="255" label="-2.25" value="-2.25" color="#f59053"/>
        <paletteEntry alpha="255" label="-1.75" value="-1.75" color="#fdb367"/>
        <paletteEntry alpha="255" label="-1.25" value="-1.25" color="#fec980"/>
        <paletteEntry alpha="255" label="-0.75" value="-0.75" color="#fedf99"/>
        <paletteEntry alpha="255" label="-0.25" value="-0.25" color="#fff4b2"/>
        <paletteEntry alpha="255" label="0.25" value="0.25" color="#f4fabb"/>
        <paletteEntry alpha="255" label="0.75" value="0.75" color="#ddf1b4"/>
        <paletteEntry alpha="255" label="1.25" value="1.25" color="#c7e8ad"/>
        <paletteEntry alpha="255" label="1.75" value="1.75" color="#b1dfa6"/>
        <paletteEntry alpha="255" label="2.25" value="2.25" color="#91cba8"/>
        <paletteEntry alpha="255" label="2.75" value="2.75" color="#6fb3ae"/>
        <paletteEntry alpha="255" label="3.25" value="3.25" color="#4d9bb4"/>
        <paletteEntry alpha="255" label="3.75" value="3.75" color="#2b83ba"/>
      </colorPalette>
      <colorramp name="[source]" type="gradient">
        <Option type="Map">
          <Option name="color1" type="QString" value="215,25,28,255"/>
          <Option name="color2" type="QString" value="43,131,186,255"/>
          <Option name="discrete" type="QString" value="0"/>
          <Option name="rampType" type="QString" value="gradient"/>
          <Option name="stops" type="QString" value="0.25;253,174,97,255:0.5;255,255,191,255:0.75;171,221,164,255"/>
        </Option>
        <prop v="215,25,28,255" k="color1"/>
        <prop v="43,131,186,255" k="color2"/>
        <prop v="0" k="discrete"/>
        <prop v="gradient" k="rampType"/>
        <prop v="0.25;253,174,97,255:0.5;255,255,191,255:0.75;171,221,164,255" k="stops"/>
      </colorramp>
    </rasterrenderer>
    <brightnesscontrast brightness="0" contrast="0" gamma="1"/>
    <huesaturation grayscaleMode="0" colorizeStrength="100" invertColors="0" colorizeOn="0" colorizeBlue="128" saturation="0" colorizeRed="255" colorizeGreen="128"/>
    <rasterresampler maxOversampling="2"/>
    <resamplingStage>resamplingFilter</resamplingStage>
  </pipe>
  <blendMode>0</blendMode>
</qgis>
