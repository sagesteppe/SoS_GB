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


### Estimating the Number of seeds you have collected

This is very similar to the above, where we wanted to estimate the collection weight required to reach an amount of seed. Some of the terms are just slightly rearranged. 

1) To a well mixed collection of seeds, take a sample of seeds. In an operational context this is likely to only be 0.1% of the number of seeds in most circumstances! If possible have the sample be a 'round' weight, or round number of seeds (e.g. 1 gram, or 100 seeds); Doing this can help you see if any math errors occur more quickly.
2) Weigh, and count the seeds. Do not remove additional debris from the sample! That weight matters.
3) Take a subsample of roughly 50-100 seeds from the sample to perform cut tests on. Line them up in grids like 5 seeds per row and 10 columns.
4) perform a cut test on a wet paper towel, or your tape. Recording the number of seeds which are viable, or non-viable.
5) weigh the entire collection.

1a) sample = 1 gram
2a) 87 seeds in the sample
3a) 50 seed subsample
4a) 26 seeds viable
5a) collection weighs 554 grams

$$ \frac{\text{87 seeds}}{\text{1 gram}}} * \frac{\text{26 viable seeds}}{\text{50 seeds cut}}} * \frac{\text{554 grams}}{\text{454 grams/lb}} $$

## Environmental Niche Models the New Arid West Batch


| Layer |                       Description                       |              Source                            
| :---: | :-----------------------------------------------------: | :-----------------------------------: |  
|  1.   |              Mean Annual Air Temperature (BIO1)         |       PRISM / CLIMATENA/ DISMO        |
|  2.   |                 Temperature seasonality (BIO4)          |             Wang et al.               |
|  3.   |         Max Temperature of Warmest Month (BIO5)         |        PRISM / CLIMATENA / DISMO      |
|  4.   |         Min Temperature of Coldest Month (BIO6)         |        PRISM / CLIMATENA / DISMO      |
|  5.   |        Mean Temperature of Warmest Quarter (BIO10)      |        PRISM / CLIMATENA / DISMO      |
|  6.   |        Mean Temperature of Coldest Quarter (BIO11)      |        PRISM / CLIMATENA / DISMO      |
|  7.   |              Mean annual precipitation (BIO12)          |        PRISM / CLIMATENA / DISMO      |
|  8.   |         Precipitation of Warmest Quarter (BIO18)        |        PRISM / CLIMATENA / DISMO      |
|  9.   |        Precipitation of Colest Quarter (BIO19)          |        PRISM / CLIMATENA / DISMO      |
| 10.   |                Mean annual cloudiness - MODIS           |          Wilson et al. 2016           |
| 12.   |         Beginning of the frost-free period (gdgfgd0)    |              Wang et al.              |
| 12.   |                   Climatic moisture deficit             |              Wang et al.              |
| 13.   |                  Degree-days above 5C (gdd5)            |              Wang et al.              |
| 14.   |               Mean annual precipitation as snow         |              Wang et al.              |
| 15.   |                 Percent Herbaceous Vegetation           |               EarthEnv                |
| 16.   |                     Percent Shrub Cover                 |               EarthEnv                |
| 17.   |                      Percent Tree Cover                 |               EarthEnv                |
| 18.   |          Soil probability of bedrock (R Horizon)        |              SoilGrids                |
| 19.   |                Soil organic carbon (Tonnes / ha)        |              SoilGrids                |
| 20.   |                Surface (0-5 cm) soil pH in H~2~O        |              SoilGrids                |
| 21.   |                   30-60 cm soil pH in H~2~O             |              SoilGrids                |
| 22.   |                Surface (0-5 cm) soil % sand             |              SoilGrids                |
| 23.   |                    5-15 cm  soil % sand                 |              SoilGrids                |
| 24.   |                    15-30 cm soil % sand                 |              SoilGrids                |
| 25.   |                Surface (0-5 cm) soil % clay             |              SoilGrids                |
| 26.   |                    5-15 cm  soil % clay                 |              SoilGrids                |
| 27.   |                    15-30 cm soil % clay                 |              SoilGrids                |
| 28.   |              Surface (0-5 cm) coarse fragments          |              SoilGrids                |
| 29.   |                      Soil USDA class                    |              SoilGrids                |
| 30.   |                         Elevation                       |             Geomorpho90               |
| 31.   |                          Slope                          |             Geomorpho90               |
| 32.   |                          Aspect                         |             Geomorpho90               |
| 33.   |                 Topographic Wetness Index               |             Geomorpho90               |
| 34.   |                  Terrain ruggedness Index               |             Geomorpho90               |
| 35.   |                       Geomorphon                        |             Geomoprho90               |
| 36.   |        Estimated actual (w/-cloud) solar radiation      |      r.sun / Wilson et al. 2016       |
| 37.   |        Log-transformed distance to surface water        |     Global Surface Water Explorer     |
| 38.   |                 Human Influence Index Map               | TIRGRIS / HDX/ BTS Rail Network /     |
|       |                                                         |           NASA NTL  / NLCD            |


