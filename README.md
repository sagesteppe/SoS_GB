This repository holds much of the work for the Seeds of Success IDIQ for the Great Basin 2023. 


## Equations for Crews

### Estimator of whether a population can support an SoS collection

<center>

$$\frac{\text{No. Plants}}{\text{Population}} * \frac{\text{No. Inflorescence}}{\text{Plant}} * \frac{\text{No. Flowers}}{\text{Inflorescence}}*\frac{\text{No. Seeds}}{\text{Fruit}} * 0.2 = \frac{\text{Harvestable yield}}{\text{Population}}$$ 

Because the terms underneath the equation cancel out, it may readily be simplified to:

$$\text{No. Plants} * \text{No. Inflorescence} *\text{No. Flowers} * \text{No. Seeds} * 0.2=\text{Harvestable yield}$$ 

By substituting the variable names with abbreviations we then have

$$\text{pl} * \text{infl} * \text{flr} * \text{sds} * 0.2 = \text{Harvestable yield}$$ 

We can also rearrange the equation to move the maximum allowable harvest ratio constant to underneath the variables

$$\frac{\text{pl} * \text{infl} * \text{flr} * \text{sds}}{5} = \text{Harvestable yield}$$ 

And it is that easy!

Now a worked example is:

A population of *Lomatium triternatum* has roughly **1,000 plants**, each of which has a mean of **5 inflorescence**, which produce a mean of **100 flowers**, which each produce a mean  of **1.8 seeds**. What is the estimated amount of seeds which this population will yield?

$$\frac{\text{1,000} * \text{5} *\text{100} * \text{1.8}}{5} = \text{180,000 harvestable seeds}$$

### Estimating the weight of seeds using Pure Live Seed needed to reach a collection

If we are trying to determine whether we have collected enough seeds the follow formula may be used

$$\frac{\text{No. Seeds Goal} * \frac{\text{No. Cut Seeds}}{\text{No. Viable Seeds}}}{\frac{\text{No. Seeds}}{\text{Unit Weight}}} = \text{No. Units Weight}$$ 

This is simpler than it looks, essentially all we need to do is multiple our target number of seeds, by the proportion of seeds which appear viable, and divide this by our unit of measurement. 

For example, let us say that we are in the field collecting from that *Lomatium triternatum* population on Thursday morning, and we want to know when we can go home. Our goal is to collect **100,000** seeds, and we **cut test 20 seeds** and we think that **16 of them appear viable**, meaning our proportion of viable seeds is **0.8**, but that our ratio of the **seeds cut** to **viable seeds** is 1.25. We know that **23 seeds weigh 1 gram**

$$\frac{100,000 * 1.25}{23} = \text{5,434 units weight}$$ 

And we can see that $125000 * 0.8 = 100,000$, so we have the estimates for the number of seeds we need in a unit weight.

We can convert this unit weight to a larger one, because 5,434 is a big (totally fictitious) number. Because we know that there are $\frac{\text{453.492 grams}}{\text{1 pound}}$ we can very simply:

$$\frac{\text{5434 grams}}{\text{453.5 grams/lb}} = \text{12 pounds seed}$$
  
</center>


## Environmental Niche Models the New Arid West Batch

Layer                        Description                                   Source
----        -------------------------------------------------   ------------------------------------
1.                   Mean annual cloudiness - MODIS                  Wilson et al. 2016
2.            Beginning of the frost-free period (gdgfgd0)              Wang et al.
3.                      Climatic moisture deficit                       Wang et al.
4.                      Degree-days above 5C (gdd5)                     Wang et al.
5.                   Mean annual precipitation (BIO12)                  Wang et al.
6.                  Mean annual precipitation as snow                   Wang et al.
7.                    Temperature seasonality (BIO4)                    Wang et al.
8.                    Percent Herbaceous Vegetation                      EarthEnv
9.                        Percent Shrub Cover                            EarthEnv
10.                         Percent Barren                               EarthEnv
11.             Soil probability of bedrock (R Horizon)                  SoilGrids
12.                   Soil organic carbon (Tonnes / ha)                  SoilGrids
13.                   Surface (0-5 cm) soil pH in H~2~O                  SoilGrids
14.                      30-60 cm soil pH in H~2~O                       SoilGrids
15.                   Surface (0-5 cm) soil % sand                       SoilGrids
16.                       5-15 cm  soil % sand                           SoilGrids
17.                       15-30 cm soil % sand                           SoilGrids
18.                   Surface (0-5 cm) soil % clay                       SoilGrids
19.                       5-15 cm  soil % clay                           SoilGrids
20.                       15-30 cm soil % clay                           SoilGrids
21.                 Surface (0-5 cm) coarse fragments                    SoilGrids
22.                         Soil USDA class                              SoilGrids
28.                            Elevation                                Geomorpho90
29.                             Slope                                   Geomorpho90
30.                             Aspect                                  Geomorpho90
31.                    Topographic Wetness Index                        Geomorpho90
32.                     Terrain ruggedness Index                        Geomorpho90
33.                          Geomorphon                                 Geomoprho90
34.           Estimated actual (w/-cloud) solar radiation         r.sun / Wilson et al. 2016
35.           Log-transformed distance to surface water          Global Surface Water Explorer
36.                 Mean Annual Air Temperature (BIO1)             PRISM / CLIMATENA/ DISMO
37.            Max Temperature of Warmest Month (BIO5)             PRISM / CLIMATENA/ DISMO
38.            Min Temperature of Coldest Month (BIO6)             PRISM / CLIMATENA/ DISMO
39.           Mean Temperature of Warmest Quarter (BIO10)          PRISM / CLIMATENA/ DISMO
40.           Mean Temperature of Coldest Quarter (BIO11)          PRISM / CLIMATENA/ DISMO
41.            Precipitation of Warmest Quarter (BIO18)            PRISM / CLIMATENA/ DISMO
----      ---------------------------------------------------   ----------------------------------

