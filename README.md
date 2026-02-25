# FS25_AdvancedDamageSystem

Advanced Damage System is a complete overhaul of the vehicle maintenance system, transforming it into a deep and strategic layer of gameplay. Forget the simple "Repair" button—now every tractor requires a thoughtful approach.

<table>
<tr>
<td width="65%" valign="top">

> [!WARNING]
> **IMPORTANT WARNING**
>
> *   This mod is a work in progress (WIP). Features are subject to change, and bugs are to be expected.
> *   Use at your own risk. The author is not responsible for any potential issues with your savegame or game. It is strongly recommended to back up your saves.
> *   Multiplayer (MP) is not currently supported. Support is planned for a future release.

</td>
<td width="35%" align="center" valign="top">
<img width="256" height="256" alt="icon_ads" src="https://github.com/user-attachments/assets/ac09c1b1-daa3-4026-b312-b09156d9a03e" />

</td>
</tr>
</table>

# Acknowledgements 

A huge thank you to **Frvetz** (https://github.com/Frvetz), creator of the Realistic Damage System mod for FS22, for the permission to use ideas from his mod and for the support during the early stages of development.
Also, a big thank you to **Derwen Modding** for testing the early builds.

# Key Features
- **Complete Replacement of the Vanilla Damage System:** Wear now accumulates based on how you operate your vehicle. Harsh usage (for example, overloading the engine) causes significantly faster deterioration.
- **Regular Maintenance Becomes Essential:** Scheduled service is now required to prevent accelerated wear and avoid costly failures.
- **Dynamic Breakdowns:** Dozens of unique malfunctions can occur, each with its own gameplay effects.
- **Fully Reworked Workshop Menu and Logic:** The workshop now supports inspection, repair, maintenance, and overhaul. Each procedure has configurable options and takes time to complete, so there is no one-click repair.
- **Realistic Thermal Simulation:** Engines need proper warm-up, and they can overheat under heavy load in hot conditions. Ignoring temperature can lead to serious consequences.
- **Vehicle-Specific Characteristics:** Vehicles differ by brand and production year in Reliability (affecting wear rate, breakdown probability, and service intervals) and Maintainability (affecting service cost and service time). Premium brands are generally more reliable than budget alternatives, while older machines are often mechanically simpler and therefore more maintainable.

  ... More information below in the guide

Demonstration of some breakdown's effects: https://www.youtube.com/watch?v=NpnlvY25Xl0&list=PL73V6HaxZ69gRgpLGkHpb_k5Qh1w4ZtHa

# Console Commands
For testing and debugging, ADS includes console commands. Most commands require you to be inside a vehicle that supports this mod.

| Command | Description | Usage Example |
| --- | --- | --- |
| **ads_debug** | Toggles ADS debug mode on/off. | `ads_debug` |
| **ads_listBreakdowns** | Lists all available breakdown IDs from the registry. | `ads_listBreakdowns` |
| **ads_addBreakdown** | Adds a breakdown to the current vehicle. If no ID is provided, a random one is added at stage 1. | `ads_addBreakdown ECU_MALFUNCTION 2` |
| **ads_removeBreakdown** | Removes a specific breakdown from the current vehicle. If no ID is provided, removes all active breakdowns. | `ads_removeBreakdown ECU_MALFUNCTION` |
| **ads_advanceBreakdown** | Advances a specific active breakdown by one stage. If no ID is provided, advances all active breakdowns (if possible). | `ads_advanceBreakdown ECU_MALFUNCTION` |
| **ads_setCondition** | Sets the current vehicle's Condition level (`0.0`-`1.0`). | `ads_setCondition 0.5` |
| **ads_setService** | Sets the current vehicle's Service level (`0.0`-`1.0`). | `ads_setService 0.2` |
| **ads_resetVehicle** | Fully resets the current vehicle state (Condition and Service to `1.0`, clears breakdowns). | `ads_resetVehicle` |
| **ads_startService** | Starts workshop service for the current vehicle. Types: `inspection`, `maintenance`, `repair`, `overhaul`. Optional `[count]` is used with `repair` to select how many visible breakdowns to repair. | `ads_startService repair 2` |
| **ads_finishService** | Instantly finishes the currently active service on the current vehicle. | `ads_finishService` |
| **ads_getServiceState** | Prints detailed current workshop/service state variables for the current vehicle. | `ads_getServiceState` |
| **ads_showServiceLog** | Shows maintenance/service log entries. Optional `[index]` prints a detailed single entry. | `ads_showServiceLog 1` |
| **ads_getDebugVehicleInfo** | Prints debug information about the current vehicle. Optional argument prints attached specializations list. | `ads_getDebugVehicleInfo 1` |

# Screenshots
<img width="2560" height="1600" alt="FarmingSimulator2025Game 2025-07-17 18-29-33_123" src="https://github.com/user-attachments/assets/c7fcaecf-2814-4ac8-a12e-631be8617d18" />
<img width="962" height="589" alt="2" src="https://github.com/user-attachments/assets/f002ea0d-cb21-4c9d-a513-c7f771cbd62e" />
<img width="963" height="595" alt="1" src="https://github.com/user-attachments/assets/194ff2d1-a715-43cb-919e-92c648a2fad8" />
<img width="931" height="569" alt="3" src="https://github.com/user-attachments/assets/cda5e2a4-fa4b-491e-a817-078b8631470b" />
<img width="1253" height="763" alt="image" src="https://github.com/user-attachments/assets/18fe2f51-44f8-46fe-a1ac-8b892d25852c" />
<img width="2560" height="1600" alt="FarmingSimulator2025Game 2025-07-17 18-34-40_109" src="https://github.com/user-attachments/assets/39c982bc-034d-4f9f-a025-6802d63f201f" />
<img width="1967" height="1209" alt="Снимок экрана 2026-02-24 221501" src="https://github.com/user-attachments/assets/2c54b8a0-f5f6-4251-8ca5-397ac87be25b" />

# Mod Guide
The Advanced Damage System (ADS) mod completely replaces the standard damage system, offering a deep and detailed simulation of wear, breakdowns, and technical service.
This guide will help you understand all aspects of the mod.


## 1. Core Mechanics: Condition and Service

ADS introduces two key parameters for each of your vehicles:

### ⚙️ Condition

This is the main indicator of your vehicle's "health." It reflects the overall physical wear of the engine, transmission, hydraulics, and other key components.

- **What does Condition affect?**
It directly impacts the probability of breakdowns occurring and the speed of their progression. The lower the condition, the more often the vehicle breaks down, and the faster a malfunction reaches a critical stage.

- **How does it decrease?**
It decreases as the vehicle is used. With default settings and for a vehicle of average quality, this is about 1% per operating hour. However, the rate of wear is heavily influenced by the following factors:

  - Working Under Load: The harder the engine is working, the faster the vehicle wears out.

  - Overdue Service: If you don't change the oil and filters, the wear of all components accelerates significantly.

  - Operating a Cold Engine: Putting a heavy load on an unheated engine causes increased wear.

  - Overheating: Operating at critical engine or transmission temperatures will rapidly "kill" your vehicle.

  - Vehicle Reliability: Each brand and model has its own reliability rating. Premium brand vehicles wear out more slowly.
 
- **How to restore Condition?**
It can only be partically restored through the Overhaul procedure in the workshop.

> [!NOTE]
> <details>
> <summary><strong>⚙️ Click here for a detailed breakdown of Condition wear mechanics</strong></summary>
>
> The final wear rate is calculated using a formula that combines a base rate with several dynamic multipliers.
> 
> ### 1. Base Wear Rate
> This is the starting point for wear calculation (these parameters can be adjusted in the settings):
> - **Standard Operation:** `1%` per operating hour.
> - **Engine Idling:** `0.5%` per operating hour (wear is halved).
> - **Passive Wear (Engine Off):** `0.05%` per hour, simulating natural degradation from environmental factors.
> 
> ### 2. Wear Multipliers (Cumulative)
> These factors are applied on top of the base rate. They are designed with a quadratic curve, meaning their effect grows exponentially as the situation worsens.
> 
> - **Working Under Load:**
>   - **Threshold:** Activates above 80% engine load.
>   - **Max Penalty:** `+100%` wear at full load (effectively doubling the wear rate).
> 
> - **Overdue Service:**
>   - **Threshold:** Activates when `Service` level drops below 50%.
>   - **Max Penalty:** `+1000%` wear at 0% service. This is a major penalty for neglecting maintenance!
> 
> - **Operating a Cold Engine:**
>   - **Threshold:** Activates when engine temperature is below 50°C.
>   - **Max Penalty:** `+5000%` wear at 0°C. This is one of the most significant wear factors, so always warm up your engines!
> 
> - **Overheating:**
>   - **Threshold:** Activates above 95°C engine temperature.
>   - **Max Penalty:** `+5000%` wear at 120°C. This penalty is extremely high and is designed to rapidly degrade a vehicle if overheating is ignored.
>
> ### 3. Vehicle Reliability Modifier
> This is a final divisor applied to the total calculated wear rate. The `0.8` to `1.2` reliability range is used here as an example; actual brand values can be lower (e.g., `0.7`) or higher.
> 
> - **Reliability of 1.2 (Premium Brand):** The final wear rate is divided by 1.2, resulting in a **~17% reduction** in wear.
> - **Reliability of 1.0 (Average Brand):** The final wear rate is divided by 1.0, resulting in **no change**.
> - **Reliability of 0.8 (Budget Brand):** The final wear rate is divided by 0.8, resulting in a **25% increase** in wear.
>
> </details>


### 💧 Service

This parameter reflects the state of consumables: oil, filters, technical fluids, etc.

- **What does Service affect?**
This is a critically important parameter. A low Service level significantly accelerates the decline of Condition. Furthermore, it drastically increases the probability of random component failures. Timely maintenance is the best way to save money on expensive repairs in the future.

- **How does it decrease?**
It decreases with engine operating hours, simulating the natural wear of consumables.

- **How to restore it?**
It is restored to 100% through the Maintenance procedure in the workshop (depending on the selected maintenance scope, this value can be lower or higher).

> [!NOTE]
> <details>
> <summary><strong>⚙️ Click here for technical details on Service wear and its impact</strong></summary>
> 
> ### 1. Service Wear Rate
> The base wear rate for the `Service` level is much faster than for `Condition`, as it simulates consumable usage (these parameters can be adjusted in the settings).
> - **Standard Operation:** `10%` per operating hour.
> - **Engine Idling:** `5%` per operating hour (wear is halved).
> - **Passive Wear (Engine Off):** `0.5%` per hour.
> 
> The only modifier affecting this rate is the vehicle's **Reliability**. Just like with `Condition`, the brand's reliability rating acts as a final divisor for the total `Service` wear.
>
> ### 2. The Penalty for Overdue Service
> The mod calculates a recommended service interval for each vehicle based on its brand quality. While you are free to choose your own schedule, delaying maintenance has severe consequences. The table below shows how the penalty multiplier applied to `Condition` wear (same penalty to breakdown probability) grows exponentially as the `Service` level drops below the 50% threshold.
> 
> | Service Level | Penalty on `Condition` Wear | Service Level | Penalty on `Condition` Wear | Service Level | Penalty on `Condition` Wear |
> | :-----------: | :-------------------------: | :-----------: | :-------------------------: | :-----------: | :-------------------------: |
> | **100% - 50%**| **`+0%`**                   | **30%**       | `+160%`                     | **10%**       | `+640%`                     |
> | **45%**       | `+10%`                      | **25%**       | `+250%`                     | **5%**        | `+810%`                     |
> | **40%**       | `+40%`                      | **20%**       | `+360%`                     | **0%**        | **`+1000%`**                |
> | **35%**       | `+90%`                      | **15%**       | `+490%`                     |               |                             |

> 
> </details>

### A Note on Player Knowledge: Hidden Values
You can check `Condition` and `Service` in the workshop by running an Inspection. In most cases, the result is an approximate status (for example: Service is `OPTIMAL`, `NOT REQUIRED`, `REQUIRED`, or `OVERDUE`).

Exact percentage values are available only through a full diagnostic (defectoscopy) procedure, which is expensive and time-consuming.

In practice, this level of precision is usually unnecessary. A responsible farmer follows the manufacturer-recommended service interval for each machine, performs maintenance on schedule, and when the time comes, either carries out an overhaul or replaces the vehicle.

## 2. Breakdowns

The most interesting part of the mod. As the vehicle's Condition drops, the probability of random breakdowns increases.

> [!NOTE]
> <details>
> <summary><strong>📋 Click here for a full list of breakdowns and their effects</strong></summary>
> 
> This is a comprehensive list of all selectable (random) breakdowns in the mod. Each breakdown has several stages, with the effects becoming more severe over time. The "Critical Effect" listed is the final stage of the malfunction.
>
> ---
> 
> ### ⚙️ Engine Systems
> 
> #### ECU Malfunction
> * *Applicable to:* Modern vehicles (Year 2000+) with combustion engines.
> * *Symptoms:* Progressive power loss, increased fuel consumption, engine stalls, difficulty starting, dark exhaust smoke.
> * *Critical Effect:* **Complete engine failure.** The vehicle will not start.
> 
> #### Fuel Pump Malfunction
> * *Applicable to:* All vehicles with combustion engines.
> * *Symptoms:* Engine hesitation, occasional stalls, difficulty starting, progressive power loss, increased fuel consumption and fluctuating idle.
> * *Critical Effect:* **Complete engine failure.** Fuel is not supplied, and the engine cannot be started.
> 
> #### Fuel Injector Malfunction
> * *Applicable to:* All vehicles with combustion engines.
> * *Symptoms:* Rough engine operation, misfires under load, significant power loss, unreliable starting, fluctuating idle.
> * *Critical Effect:* **Complete engine failure.** The engine will not run correctly and may not start at all.
>
> #### Cooling System Thermostat Malfunction
> * *Applicable to:* All vehicles with combustion engines.
> * *Symptoms:* Engine takes longer to warm up or runs hotter than normal, leading to increased wear and risk of overheating.
> * *Critical Effect:* **Rapid and severe engine overheating,** as the thermostat fails completely and blocks coolant circulation.
>
> #### Carburetor Clogging
> * *Applicable to:* Older vehicles (Pre-1980) with combustion engines.
> * *Symptoms:* Engine hesitation, sputtering, frequent stalls, difficulty maintaining power and fluctuating idle.
> * *Critical Effect:* **Engine will not run** due to complete fuel starvation.
> 
> ---
> 
> ### 🔩 Transmission Systems
> 
> #### Transmission Slip
> * *Applicable to:* Vehicles with conventional (non-CVT) transmissions.
> * *Symptoms:* Occasional power loss as the transmission slips under load, especially during acceleration.
> * *Critical Effect:* **Vehicle is unable to move.** The clutch is completely burned out.
> 
> #### Transmission Synchronizer Malfunction
> * *Applicable to:* Vehicles with manual or synchro-shift transmissions.
> * *Symptoms:* Grinding noises, difficulty shifting gears, and a high chance of failed shifts or gear rejection under load.
> * *Critical Effect:* **Impossible to shift gears.**
> 
> #### Powershift Hydraulic Pump Malfunction
> * *Applicable to:* Vehicles with Powershift transmissions.
> * *Symptoms:* Delays, harshness, and violent shocks when shifting gears.
> * *Critical Effect:* **Transmission is stuck in neutral** and cannot engage any gear.
> 
> #### CVT Thermostat Malfunction
> * *Applicable to:* Modern vehicles (Year 2000+) with CVT transmissions.
> * *Symptoms:* CVT temperature becomes unstable, leading to a high risk of overheating and internal damage during prolonged work.
> * *Critical Effect:* **Rapid and dangerous overheating of the CVT** due to a complete cooling failure.
> 
> ---
> 
> ###  Other Systems
> 
> #### Brake Malfunction
> * *Applicable to:* All wheeled vehicles.
> * *Symptoms:* Increased braking distance, weak and unreliable brakes, unusual noises when braking.
> * *Critical Effect:* **Complete brake system failure.** Braking is impossible.
> 
> #### Hydraulic Pump Malfunction
> * *Applicable to:* Most non-truck vehicles (tractors, combines, etc.) from 1960 onwards.
> * *Symptoms:* Hydraulic implements become progressively slower and weaker.
> * *Critical Effect:* **The hydraulic system is completely inoperable.**
> 
> #### Electrical System Malfunction
> * *Applicable to:* Modern vehicles (Year 2000+) with lights.
> * *Symptoms:* Flickering lights, unreliable engine starting, occasional stalls.
> * *Critical Effect:* **Complete electrical failure.** Lights do not work and the starter does not respond.
> 
> ---
> 
> ### 🚜 Harvester-Specific Systems
> 
> #### Yield Sensor Malfunction
> * *Applicable to:* Modern combines (Year 2000+).
> * *Symptoms:* The automatic threshing system becomes less efficient, leading to progressively higher crop losses as the combine fails to separate grain correctly.
> * *Critical Effect:* **Severe crop loss (-40%)** as the monitoring system fails completely.
> 
> #### Material Flow System Wear
> * *Applicable to:* All combines.
> * *Symptoms:* Minor crop loss during internal transport, grinding noises, and a risk of major clogs.
> * *Critical Effect:* **Severe material flow blockage** and massive crop loss (-80%) as a major component fails. The engine is placed under extreme strain.
> 
> #### Unloading Auger Malfunction
> * *Applicable to:* Combines with unloading auger systems.
> * *Symptoms:* Progressive unloading slowdown while discharging grain.
> * *Critical Effect:* **Unloading auger failure.** Grain unloading becomes unavailable until repaired.
> 
> </details>

#### Chance and Severity of Breakdowns
Breakdown probability is influenced by three key factors: the current `Condition` level, vehicle `Reliability`, and active wear multipliers. Lower `Condition` and lower `Reliability` increase the base chance of failure, while harsh real-time operating conditions (for example, running at near-100% engine load) can further raise the chance of a breakdown in that moment, in addition to accelerating wear. For heavily worn vehicles, the probability that a breakdown appears directly at a major or critical stage, skipping minor phases, also increases significantly.

> [!NOTE]
> <details>
> <summary><strong>⚙️ Click here for technical details on breakdown probability</strong></summary>
>
> The probability of breakdowns is calculated using a formula designed to create a very noticeable difference between new and heavily-used equipment. Here are the key metrics for a vehicle of average quality:
>
> ### 1. Breakdown Frequency (MTBF)
> The system uses **Mean Time Between Failures (MTBF)** to determine breakdown frequency.
> - **New Vehicle (100% Condition):** The MTBF is **1200 minutes (20 hours)** by default. This parameter is configurable in settings.
> - **Worn-Out Vehicle (0% Condition):** The MTBF drops to **120 minutes (2 hours)**.
>
> ### 2. Critical Failure Chance
> This is the probability that a new breakdown will skip the minor stages and appear immediately as a **critical** failure.
> - **New Vehicle (100% Condition):** The chance is only **5%**.
> - **Worn-Out Vehicle (0% Condition):** The chance rises to **33%**.
>
> ### 3. Lifetime Distribution, Curve Shape, and "Honeymoon" Modifier
> Breakdown probability uses a third-degree baseline (`DEGREE = 3.0`), so the closer `Condition` gets to `0`, the faster failure probability grows.
>
> In addition, new equipment receives a "honeymoon" modifier (`VEHICLE_HONEYMOON_HOURS = 10` by default), which makes early-life random failures extremely unlikely.
>
> For a vehicle's full lifecycle (100% -> 0% Condition) without overhauls, expected breakdown counts are now roughly **2x lower** than before:
> - **Total Expected Breakdowns:** Approximately **15**.
> - **First Half of Life (100% -> 50% Condition):** Only **~2-3** breakdowns are expected.
> - **Second Half of Life (50% -> 0% Condition):** The remaining **~12-13** breakdowns occur as condition rapidly deteriorates.
>
> In practice, this means heavily worn equipment is at least **10x** more failure-prone than a new machine (and effectively even more during the honeymoon period).
>
> </details>

#### Stages and Progression
Most breakdowns go through several stages, gradually getting worse:

- **Minor:** A slight decrease in performance that might go unnoticed.

- **Moderate:** Problems become more obvious. Indicators on the dashboard may light up.

- **Major:** Significant operational problems that make using the vehicle difficult.

- **Critical:** Complete failure of a component. The engine stalls, brakes fail, etc.

If not addressed, a breakdown will progress over time. Progression is context-dependent: each breakdown has its own progression conditions. For example, unloading-system faults on combines progress only while the machine is unloading crop, which is intentionally modeled this way for realism.

#### Cost and Detection
With each new stage, the cost of repair increases. A critical breakdown can be very costly. For modern vehicles, the mod adds dashboard indicators that usually report a problem starting from the second stage.

#### It Pays to Be Attentive!
The cheapest repair is a preventive one. Keep an eye on—and an ear out for—your equipment. The initial stages of a breakdown are accompanied by various visual and audio cues that serve as early warning signs. This might manifest as fluctuating engine RPMs, dark exhaust smoke, or other unusual noises like knocking or squeaking during operation. If you catch these symptoms during the first, hidden stage and promptly take your vehicle for an Inspection, you can fix the problem for a minimal price.

> [!NOTE]
> <details>
> <summary><strong>⚙️ Click here for technical details on progression and repair costs</strong></summary>
>
> ### 1. Dashboard Indicators
> In modern tractors, any deviation from the norm would typically trigger a dashboard warning. However, to make gameplay more engaging, indicators are intentionally disabled for the **first (Minor) stage** of a breakdown. This is designed to reward attentive players who can detect subtle changes in their vehicle's performance, allowing them to save significantly on repair costs. Most indicators will activate starting from the **second (Moderate) stage**.
>
> ### 2. Repair Cost Scaling
> The cost of fixing a breakdown scales exponentially with its progression:
> - Each subsequent stage **doubles (x2)** the repair cost of the previous one.
> - The base repair cost for a new breakdown is unique for each type of malfunction, but it generally hovers around **1% of the vehicle's total value**. The logic is based on realism: fixing the electrical system will naturally be much cheaper than repairing the transmission.
>
> ### 3. Breakdown Progression Speed
> Breakdown progression speed is not static.
> - It depends on the current `Condition` level: the lower the condition, the faster breakdowns progress.
> - Each breakdown has its own progression speed and behavior rules.
>
> </details>

#### General Wear and Tear
Beyond random failures, low condition can trigger a permanent "General Wear and Tear" effect, simulating the sluggishness and aging behavior of worn machinery.

> [!NOTE]
> <details>
> <summary><strong>⚙️ Click here for technical details on the "General Wear and Tear" effect</strong></summary>
>
> The "General Wear and Tear" effect begins to apply once a vehicle's `Condition` drops below **50%** (configurable in `ADS_Config.lua` via `GENERAL_WEAR_THRESHOLD`). Its impact is calculated using a cubic formula, so effects are mild at first and become much stronger as `Condition` approaches zero.
>
> This effect applies several penalties, which reach their maximum values at 0% `Condition`:
>
> - **Engine Power Reduction:** Up to **-30%**.
> - **Braking Effectiveness Reduction:** Up to **-30%**.
> - **Engine Start Reliability:** Start-failure chance increases (up to **66%**).
> - **Cooling System Margin:** Thermostat health is reduced (up to **-30%**), increasing overheating risk.
> - **Harvesting Efficiency Loss (for harvesters):** Up to **-30%**, simulating increased crop loss from worn-out components.
>
> </details>

## 3. Workshop Repairs and Service

The workshop system has been fully reworked. You now choose between four core procedures: **Inspection**, **Maintenance**, **Repair**, and **Overhaul**.

You can also configure additional service parameters. For example, you can choose part quality (**Used**, **Aftermarket**, **OEM**, **Premium**) or set the desired maintenance scope.

These options directly affect service **duration**, **cost**, and **quality**. All procedures now take meaningful time, so maintenance planning is an important part of fleet management.

#### Inspection

- **Inspection types:**

  - **Visual Inspection:** A quick external check. It can detect only breakdowns that have already reached stage 2+ (Moderate and above).

  - **Standard Inspection:** Checks all breakdown stages (including early ones, subject to detection chance) and generates a standard report.

  - **Complete Defectoscopy:** Checks all breakdown stages and generates a full report with exact numeric values (including precise `Condition`/`Service` percentages, estimated breakdown metrics, and detailed system health data).

- **When to use:** Whenever you feel something is "wrong" with the vehicle, when a warning light is on the dashboard, or when you want to know the exact state of your machine.

> [!NOTE]
> <details>
> <summary><strong>⚙️ Click here for technical details on Inspection types, time, and price</strong></summary>
>
> Values below are taken from `ADS_Config.lua` (`MAINTENANCE` section).
>
> ### 1. Base Parameters
> - `INSTANT_INSPECTION = false` (default)
> - `INSPECTION_TIME = 3600000 ms` (**1 hour** base time)
> - `INSPECTION_TIME_MULTIPLIERS`: `STANDARD = 1.0`, `VISUAL = 0.1`, `COMPLETE = 4.0`
> - `INSPECTION_PRICE_MULTIPLIERS`: `STANDARD = 1.0`, `VISUAL = 0.1`, `COMPLETE = 4.0`
> - If `INSTANT_INSPECTION = true`, inspection duration is forced to ~`1000 ms`; visual mode is internally converted to standard mode.
>
> ### 2. Relative Time and Price vs Standard Inspection
> - **Visual (`0.1x`)**: about **90% faster** and **90% cheaper**.
> - **Standard (`1.0x`)**: baseline.
> - **Complete (`4.0x`)**: about **4x longer** and **4x more expensive** (roughly **+300%**).
>
> ### 3. Detection Logic by Type
> - **Visual**: can only reveal breakdowns at stage **2+**.
> - **Standard / Complete**: can reveal breakdowns from **all stages**.
>
> ### 4. Report Depth by Type
> - **Visual**: no full technical report.
> - **Standard**: standard qualitative report (state labels and limited metrics).
> - **Complete**: full quantitative report with exact values and advanced metrics.
>
> ### 5. Additional Modifiers
> Final duration and price are also influenced by other game variables (for example global service multipliers, workshop context, and vehicle characteristics), so actual values can differ from the base multipliers above.
>
> </details>

#### Maintenance

- **What it does:** Replaces all oils, filters, and fluids. Service outcome depends on the selected maintenance scope:

  - **Minimal:** Basic service. Significantly cheaper and faster, but does not fully restore the Service Level.

  - **Standard:** Routine maintenance according to manufacturer specifications. Restores Service Level to normal.

  - **Extended:** Comprehensive service. Takes longer and costs more, but boosts Service Level by an additional ~20%.

- **When to use:** Regularly! However, keep in mind that the cost of this procedure is **fixed** and does not depend on the actual Service level. This means servicing a vehicle at 90% costs the same as servicing it at 10%, so finding the right balance is key to managing your budget.


> [!NOTE]
> <details>
> <summary><strong>⚙️ Click here for technical details on Maintenance levels, time, and price</strong></summary>
>
> Values below are taken from `ADS_Config.lua` (`MAINTENANCE` section).
>
> ### 1. Base Parameters
> - `MAINTENANCE_TIME = 21600000 ms` (**6 hours** base time)
> - `MAINTENANCE_TIME_MULTIPLIERS`: `MINIMAL = 0.25`, `STANDARD = 1.0`, `EXTENDED = 1.5`
> - `MAINTENANCE_PRICE_MULTIPLIERS`: `MINIMAL = 0.65`, `STANDARD = 1.0`, `EXTENDED = 1.25`
> - `MAINTENANCE_SERVICE_RESTORE_MULTIPLIERS`: `MINIMAL = 0.75`, `STANDARD = 1.0`, `EXTENDED = 1.2`
>
> ### 2. Relative Time and Price vs Standard Maintenance
> - **Minimal**: about **75% faster** and **35% cheaper**.
> - **Standard**: baseline.
> - **Extended**: about **50% longer** and **25% more expensive**.
>
> ### 3. Service Restore Target by Level
> - **Minimal:** target restore multiplier `0.75`
> - **Standard:** target restore multiplier `1.0`
> - **Extended:** target restore multiplier `1.2`
>
> ### 4. Additional Modifiers
> Final maintenance cost and duration are additionally affected by factors such as selected consumables quality, global service multipliers, workshop location multipliers, and vehicle characteristics.
>
> </details>

#### Repair

- **What it does:** Fixes specific, diagnosed breakdowns. You can choose which malfunctions to fix and which to leave for later (e.g., if you're short on cash).

  Repair also supports urgency options:

  - **When mechanics are free** (`Low Priority`)
  - **Standard queue** (`Standard Queue`)
  - **Urgent** (`Urgent`)

  These options affect both repair duration and labor cost.

  You can also choose spare-parts quality for repairs (`Used`, `Aftermarket`, `OEM`, `Premium`). More details are provided below.

- **When to use:** When you have one or more diagnosed breakdowns that are hindering your work.

> [!NOTE]
> <details>
> <summary><strong>⚙️ Click here for technical details on Repair urgency, time, and price</strong></summary>
>
> Values below are taken from `ADS_Config.lua` (`MAINTENANCE` section).
>
> ### 1. Base Parameters
> - `REPAIR_TIME = 14400000 ms` (**4 hours** base time per selected breakdown)
> - `REPAIR_TIME_MULTIPLIERS`: `LOW = 1.5`, `MEDIUM = 1.0`, `HIGH = 0.5`
> - `REPAIR_PRICE_MULTIPLIERS`: `LOW = 0.8`, `MEDIUM = 1.0`, `HIGH = 1.2`
>
> ### 2. Relative Time and Labor Cost vs Standard Queue
> - **Low Priority (`1.5x` time / `0.8x` labor)**: about **50% slower**, about **20% cheaper** labor.
> - **Standard Queue (`1.0x`)**: baseline.
> - **Urgent (`0.5x` time / `1.2x` labor)**: about **50% faster**, about **20% more expensive** labor.
>
> ### 3. Repair Scope Scaling
> Repair duration scales with the number of selected breakdowns, so multi-fault repairs can take significantly longer.
>
> ### 4. Spare-Parts Price Multipliers (for Repair Option Two)
> - `USED = 0.33`
> - `AFTERMARKET = 0.66`
> - `OEM = 1.0`
> - `PREMIUM = 1.2`
>
> ### 5. Additional Modifiers
> Final repair cost and duration are additionally affected by factors such as global service multipliers, workshop location multipliers, vehicle age, and vehicle characteristics.
>
> </details>

#### Overhaul

- **What it does:** The most comprehensive and expensive type of work. It includes:

  - A full Maintenance service.

  - Repair of all existing breakdowns.

  - Partial restoration of the vehicle's Condition (worn parts are replaced).

  Overhaul comes in three variants:
  - **Partial**
  - **Standard**
  - **Factory Restoration** (`Full`)

  Depending on the selected overhaul type, **price**, **duration**, and **Condition restoration level** are different.

- **When to use:** For old, heavily worn-out vehicles with low Condition to bring them back to life.

**Important:** This procedure is expensive and does not fully restore Condition to 100%. The amount of restored condition depends on vehicle maintainability, the number of previous overhauls, and a random restoration factor. For an additional fee (significantly lower than a regular repaint), you can also repaint the vehicle during overhaul.

> [!NOTE]
> <details>
> <summary><strong>⚙️ Click here for technical details on the Overhaul mechanic</strong></summary>
>
> Values below are based on `ADS_Config.lua` and `initService` logic in `ADS_Specialization.lua`.
>
> ### 1. Overhaul Types and Targets
> - **Partial (`PARTIAL`)**: target range `0.41` to `0.59`
> - **Standard (`STANDARD`)**: target range `0.61` to `0.79`
> - **Factory Restoration (`FULL`)**: target range `0.81` to `0.99`
>
> ### 2. Time and Price Multipliers
> - `OVERHAUL_TIME = 86400000 ms` (**24 hours** base)
> - `OVERHAUL_TIME_MULTIPLIERS`: `PARTIAL = 0.5`, `STANDARD = 1.0`, `FULL = 2.0`
> - `OVERHAUL_PRICE_MULTIPLIERS`: `PARTIAL = 0.3`, `STANDARD = 0.5`, `FULL = 0.8`
>
> Relative to **Standard**:
> - **Partial**: about **50% faster**, about **40% cheaper**.
> - **Factory Restoration (Full)**: about **100% longer**, about **60% more expensive**.
>
> ### 3. Condition Restore Formula (current implementation)
> For selected overhaul type with base range `[min, max]` and `n` previous overhauls:
> - `minAdjusted = min * (1 - RE_OVERHAUL_FACTOR * n)`
> - `maxAdjusted = max * (1 - RE_OVERHAUL_FACTOR * n)`
> - `sampledRestore = random(minAdjusted, maxAdjusted) * maintainability`
> - `targetCondition = max(currentCondition, max(sampledRestore, min))`
>
> Where `RE_OVERHAUL_FACTOR = 0.1` by default.  
> This means repeated overhauls reduce the effective restoration range over time.
>
> ### 4. Optional Paint Renewal During Overhaul
> If paint renewal is enabled during overhaul, extra repaint cost is added as:
> - `0.25 * Wearable.calculateRepaintPrice(...)`
>
> This is significantly cheaper than a regular full repaint.
>
> </details>

#### Parts Quality Options

For **Maintenance** and **Repair**, you can choose between four part qualities:

- **Used** (`Used`)
- **Budget analogs** (`Aftermarket`)
- **Original parts** (`OEM`)
- **Premium parts** (`Premium`)

These options differ by cost and defect probability.

> [!NOTE]
> <details>
> <summary><strong>⚙️ Click here for technical details on part quality, defect chance, and related breakdowns</strong></summary>
>
> Values below are taken from `ADS_Config.lua` (`MAINTENANCE` section).
>
> ### 1. Part Price Multipliers
> - `USED = 0.33`
> - `AFTERMARKET = 0.66`
> - `OEM = 1.0`
> - `PREMIUM = 1.2`
>
> ### 2. Defect Probability by Part Quality
> - `USED = 0.50` (**50%**)
> - `AFTERMARKET = 0.33` (**33%**)
> - `OEM = 0.10` (**10%**)
> - `PREMIUM = 0.00` (**0%**)
>
> ### 3. How Defect Rolls Are Applied
> - During **Maintenance**, one defect roll is performed when service completes.
> - During **Repair**, a defect roll is performed per repaired breakdown step.
>
> ### 4. Service-Related Breakdown Effects from Defective Parts
> - **`MAINTENANCE_WITH_POOR_QUALITY_CONSUMABLES`**
>   - Applies `CONDITION_WEAR_MODIFIER = +0.33`
>   - Applies `SERVICE_WEAR_MODIFIER = +0.33`
>   - Then self-removes automatically.
>
> - **`REPAIR_WITH_POOR_QUALITY_PARTS`**
>   - Triggers `REPEATED_BREAKDOWN_EFFECT` (can re-introduce a repaired fault at stage 1)
>   - Then self-removes automatically.
>
> </details>

#### ⏱️ Time and Planning
Beyond money, all workshop procedures require time. The duration of a service or repair depends on the vehicle's Maintainability (simpler machines are fixed faster).

 **Important:** The workshop has operating hours. All work is paused overnight and resumes only when the workshop opens the next day.
 
 This adds a new layer of strategy: you now need to plan when to take your vehicles in for service. An urgent repair on a combine during the harvest season might extend into the next day, leading to downtime and financial loss.

## 4. Reliability and Maintainability

Each brand of vehicle in the game now has two parameters based on its real-world reputation:

#### ✅ Reliability

- **What it is**: Shows how well-made the vehicle is. Displayed with a checkmark icon in the shop menu.

- **What it affects:** A vehicle with high reliability loses Condition more slowly, has a lower base probability of random breakdowns and has longer service intervals

Examples: Premium European and American brands are generally more reliable than budget or older Eastern European counterparts.

#### 🔧 Maintainability

- **What it is:** Shows how easily and cheaply the vehicle can be serviced and repaired.

- **What it affects:** A vehicle with high maintainability requires less money and time for all workshop operations and restores its Condition better after an overhaul.

Examples: Simple, older vehicles are often more maintainable than modern machines packed with electronics.

> [!NOTE]
> <details>
> <summary><strong>⚙️ Click here for technical details on characteristic values</strong></summary>
>
> ### Value Ranges
> In the current `ADS_Config.BRANDS` defaults:
> - **Reliability** ranges from **`0.70`** to **`1.25`**.
> - **Maintainability** ranges from **`0.65`** to **`1.55`**.
>
> ### Production Year Bonus
> Maintainability gets an additional year-based bonus in `getBrandReliability(...)`:
> - If `year < RELIABILITY_YEAR_FACTOR_THRESHOLD` (default `2000`), then
> - `yearBonus = (2000 - year) * RELIABILITY_YEAR_FACTOR` (default factor `0.01`)
> - Final maintainability (brand path): `brandMaintainability + yearBonus`
>
> Examples with default settings:
> - Year `1990` -> `+0.10` maintainability
> - Year `1980` -> `+0.20` maintainability
> - Year `1970` -> `+0.30` maintainability
>
> Note: this bonus is applied on the brand-based path; explicit model entries from the same table are used as-is.
>
> ### Configuration File
> All brand-specific values for `Reliability` and `Maintainability` can be viewed and even customized in the `ADS_Config.lua` file, located in the mod's folder.
>
> </details>

## 5. Thermal Dynamics
The mod simulates full engine heating/cooling behavior with thermostat operation. Temperature is not just visual data: it directly affects wear and failure risk.

#### Engine Thermal Model
Engine operating temperature is calculated from multiple factors:
- engine load (heat generation),
- ambient temperature,
- vehicle dirt level (radiator efficiency loss),
- airflow from speed (extra cooling while moving),
- thermostat opening state.

#### Thermostat Behavior by Vehicle Age
Thermostat control differs by production year:
- **Older machines (mechanical thermostat):** More inert behavior, slower response to changing conditions, and higher stiction.
- **Modern machines (electronic control):** Faster, PID-based thermostat response, allowing cooling efficiency to adapt much more quickly to load and temperature changes.

This is why older equipment is generally more temperature-sensitive under variable workload.

#### Overheating Protection (Limp Mode)
Modern vehicles (`year >= 2000`) use staged overheat protection:
- power is progressively limited as temperatures rise,
- at critical temperature, engine shutdown can occur.

Older vehicles do not use this staged protection logic; severe overheating can lead to a hard engine failure.

#### Warm-Up Is Required
Cold operation under load is heavily penalized. Before hard work, especially in cold weather, let the machine warm up first to reduce accelerated wear.

#### CVT Temperature Model
CVT vehicles use a dedicated transmission thermal model. Unlike the engine model (which is mainly load-driven), CVT temperature is strongly affected by:
- transmission load factor,
- slip factor (especially when actual speed is much lower than implement-limited target speed),
- acceleration dynamics (frequent acceleration/deceleration and aggressive ratio changes),
- ambient temperature, vehicle dirt, and speed-based cooling.

In practice, low-speed high-stress work and jerky driving can overheat CVT components even when engine temperature is still acceptable.

> [!NOTE]
> Thermal behavior for both engine and transmission can be tuned through `ADS_Config.lua`.
