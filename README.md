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
- **Two New Parameters:** Condition (overall mechanical wear) and Service (consumables). Poor service accelerates wear, and low condition leads to breakdowns.
- **Dynamic Breakdowns:** Dozens of malfunctions for the engine, transmission, brakes, and hydraulics. Breakdowns have several stages and progress over time if not addressed.
- **Realistic Temperature Simulation:** Overheating the engine or transmission reduces power or leads to critical failure on older equipment.
- **Brand Uniqueness:** Vehicles differ in Reliability (affecting wear rate, breakdown probability and service intervals) and Maintainability (affecting service cost and time)
- **New Workshop System:**
  - **Choice of Parts:** Decide between reliable **Genuine Parts** or cheaper **Aftermarket Parts** that come with a risk of defects.
  - **Inspection:** Detects hidden faults.
  - **Maintenance:** Restores the service level.
  - **Repair:** Fixes specific, identified breakdowns.
  - **Overhaul:** Partially restores the vehicle's overall condition.

  ... More information below in the guide

Demonstration of some breakdown's effects: https://www.youtube.com/watch?v=NpnlvY25Xl0&list=PL73V6HaxZ69gRgpLGkHpb_k5Qh1w4ZtHa

# Console Commands
For testing and debugging purposes, the mod includes several console commands. To use them, you must be inside a vehicle that supports the mod.
Command	Description	Usage Example
- **ads_debug**	Toggles the global debug mode for the mod, which prints detailed logs to the console and debug panel.	ads_debug
- **ads_listBreakdowns**	Lists all available breakdown IDs that can be added.	ads_listBreakdowns
- **ads_addBreakdown**	Adds a specific breakdown to the current vehicle. If no ID is provided, a random breakdown is added.	ads_addBreakdown ECU_MALFUNCTION 2
- **ads_removeBreakdown**	Removes a specific breakdown. If no ID is provided, removes all active breakdowns from the current vehicle.	ads_removeBreakdown ECU_MALFUNCTION
- **ads_advanceBreakdown**	Advances a specific breakdown to its next stage. If no ID is provided, attempts to advance all active breakdowns.	ads_advanceBreakdown ECU_MALFUNCTION
- **ads_setCondition**	Sets the Condition level of the current vehicle.	ads_setCondition 0.5
- **ads_setService**	Sets the Service level of the current vehicle.	ads_setService 0.2
- **ads_resetVehicle**	Fully resets the vehicle's state: sets Condition and Service to 1.0 and removes all breakdowns.	ads_resetVehicle
- **ads_startMaintance**	Starts a maintenance process for the current vehicle. Types: inspection, maintenance, repair, overhaul.	ads_startMaintance repair
- **ads_finishMaintance**	Forces the completion of any ongoing maintenance for the current vehicle.	ads_finishMaintance

# Screenshots
<img width="2560" height="1600" alt="FarmingSimulator2025Game 2025-07-17 18-29-33_123" src="https://github.com/user-attachments/assets/c7fcaecf-2814-4ac8-a12e-631be8617d18" />
<img width="2560" height="1600" alt="FarmingSimulator2025Game 2025-07-17 18-30-36_675" src="https://github.com/user-attachments/assets/7a76ced6-0c00-49d0-a780-7b8f3d564408" />
<img width="2560" height="1600" alt="FarmingSimulator2025Game 2025-07-17 18-33-54_459" src="https://github.com/user-attachments/assets/3f4eba44-0214-4a5b-aaa0-7fe897d299bd" />
<img width="2560" height="1600" alt="FarmingSimulator2025Game 2025-07-17 18-34-40_109" src="https://github.com/user-attachments/assets/39c982bc-034d-4f9f-a025-6802d63f201f" />
<img width="2560" height="1600" alt="FarmingSimulator2025Game 2025-07-17 18-35-23_442" src="https://github.com/user-attachments/assets/956f21c7-f022-42e5-8599-b0adcd9614e0" />

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
> This is the starting point for wear calculation:
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
>   - **Threshold:** Activates when `Service` level drops below 66%.
>   - **Max Penalty:** `+400%` wear at 0% service. This is a major penalty for neglecting maintenance!
> 
> - **Operating a Cold Engine:**
>   - **Threshold:** Activates when engine temperature is below 70°C.
>   - **Max Penalty:** `+1000%` wear at 0°C. This is one of the most significant wear factors, so always warm up your engines!
> 
> - **Overheating:**
>   - **Threshold:** Activates above 95°C engine temperature.
>   - **Max Penalty:** `+3000%` wear at 120°C. This penalty is extremely high and is designed to rapidly degrade a vehicle if overheating is ignored.
>
> ### 3. Vehicle Reliability Modifier
> This is a final divisor applied to the total calculated wear rate. The reliability rating for brands varies from `0.8` (less reliable) to `1.2` (very reliable).
> 
> - **Reliability of 1.2 (Premium Brand):** The final wear rate is divided by 1.2, resulting in a **~17% reduction** in wear.
> - **Reliability of 1.0 (Average Brand):** The final wear rate is divided by 1.0, resulting in **no change**.
> - **Reliability of 0.8 (Budget Brand):** The final wear rate is divided by 0.8, resulting in a **25% increase** in wear.
>
> </details>


### 💧 Service

This parameter reflects the state of consumables: oil, filters, technical fluids, etc.

- **What does Service affect?**
This is a critically important parameter. A low Service level significantly accelerates the decline of Condition. Timely maintenance is the best way to save money on expensive repairs in the future.

- **How does it decrease?**
It decreases with engine operating hours, simulating the natural wear of consumables.

- **How to restore it?**
It is restored to 100% through the Maintenance procedure in the workshop.

> [!NOTE]
> <details>
> <summary><strong>⚙️ Click here for technical details on Service wear and its impact</strong></summary>
> 
> ### 1. Service Wear Rate
> The base wear rate for the `Service` level is much faster than for `Condition`, as it simulates consumable usage.
> - **Standard Operation:** `10%` per operating hour.
> - **Engine Idling:** `5%` per operating hour (wear is halved).
> - **Passive Wear (Engine Off):** `0.5%` per hour.
> 
> The only modifier affecting this rate is the vehicle's **Reliability**. Just like with `Condition`, the brand's reliability rating acts as a final divisor for the total `Service` wear.
>
> ### 2. The Penalty for Overdue Service
> The mod calculates a recommended service interval for each vehicle based on its brand quality. While you are free to choose your own schedule, delaying maintenance has severe consequences. The table below shows how the penalty multiplier applied to `Condition` wear grows exponentially as > the `Service` level drops below the 66% threshold.
> 
> | Service Level | Penalty on `Condition` Wear | Service Level | Penalty on `Condition` Wear | Service Level | Penalty on `Condition` Wear |
> | :-----------: | :-------------------------: | :-----------: | :-------------------------: | :-----------: | :-------------------------: |
> | **100% - 67%**| **`+0%`**                   | **50%**       | `+25%`                      | **20%**       | `+196%`                     |
> | **65%**       | `+1%`                       | **45%**       | `+42%`                      | **15%**       | `+240%`                     |
> | **60%**       | `+4%`                       | **40%**       | `+64%`                      | **10%**       | `+289%`                     |
> | **55%**       | `+12%`                      | **35%**       | `+92%`                      | **5%**        | `+342%`                     |
> |               |                             | **30%**       | `+121%`                     | **0%**        | **`+400%`**                 |
> |               |                             | **25%**       | `+156%`                     |               |                             |
>
>
> </details>

### A Note on Player Knowledge: Hidden Values
A key feature of ADS is that the exact percentage values for Condition and Service are hidden from the player. This encourages you to pay attention to your vehicle's behavior rather than just numbers.

So, how do you know when to act?
- **Estimation through Inspection:** An Inspection at the workshop will give you a general assessment of your vehicle's health (e.g., "Condition is Good," "Service is Recommended").
- **The Logbook Feature:** To help you plan, the mod acts like a vehicle's logbook. It records and displays the date of the last service and the operating hours at that time. By comparing this to the current operating hours, you can accurately track how long it has been and determine when your next maintenance is due.

## 2. Breakdowns

The most interesting part of the mod. As the vehicle's Condition drops, the probability of random breakdowns increases.

> [!NOTE]
> <details>
> <summary><strong>📋 Click here for a full list of breakdowns and their effects</strong></summary>
> 
> This is a comprehensive list of all possible malfunctions in the mod. Each breakdown has several stages, with the effects becoming more severe over time. The "Critical Effect" listed is the final stage of the malfunction.
>
> ---
> 
> ### ⚙️ Engine Systems
> 
> #### ECU Malfunction
> * *Applicable to:* Modern vehicles (Year 2000+) with combustion engines.
> * *Symptoms:* Progressive power loss, increased fuel consumption, engine stalls, difficulty starting.
> * *Critical Effect:* **Complete engine failure.** The vehicle will not start.
> 
> #### Turbocharger Wear
> * *Applicable to:* Modern, powerful tractors (Year 2005+).
> * *Symptoms:* Progressive power loss, increased fuel consumption, and risk of engine stalls under load.
> * *Critical Effect:* **Severe power loss (Limp Mode).** The engine loses about 50% of its power to prevent catastrophic damage.
> 
> #### Fuel Pump Malfunction
> * *Applicable to:* All vehicles with combustion engines.
> * *Symptoms:* Engine hesitation, occasional stalls, difficulty starting, progressive power loss, and increased fuel consumption.
> * *Critical Effect:* **Complete engine failure.** Fuel is not supplied, and the engine cannot be started.
> 
> #### Fuel Injector Malfunction
> * *Applicable to:* All vehicles with combustion engines.
> * *Symptoms:* Rough engine operation, misfires under load, significant power loss, and unreliable starting.
> * *Critical Effect:* **Complete engine failure.** The engine will not run correctly and may not start at all.
>
> #### Cooling System Thermostat Malfunctio
> * *Applicable to:* All vehicles with combustion engines.
> * *Symptoms:* Engine takes longer to warm up or runs hotter than normal, leading to increased wear and risk of overheating.
> * *Critical Effect:* **Rapid and severe engine overheating,** as the thermostat fails completely and blocks coolant circulation.
>
> #### Carburetor Clogging
> * *Applicable to:* Older vehicles (Pre-1980) with combustion engines.
> * *Symptoms:* Engine hesitation, sputtering, frequent stalls, and difficulty maintaining power.
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
> #### CVT Cooling System Malfunction
> * *Applicable to:* Modern vehicles (Year 2000+) with CVT transmissions.
> * *Symptoms:* CVT temperature becomes unstable, leading to a high risk of overheating and internal damage during prolonged work.
> * *Critical Effect:* **Rapid and dangerous overheating of the CVT** due to a complete cooling failure.
> 
> ---
> 
> ###  अन्य Systems
> 
> #### Brake Malfunction
> * *Applicable to:* All wheeled vehicles.
> * *Symptoms:* Increased braking distance, weak and unreliable brakes.
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
> </details>

#### Chance and Severity of Breakdowns
The lower the vehicle's Condition, the higher the chance of a new malfunction occurring. Additionally, the vehicle's brand Reliability now plays a role: premium, more reliable brands have a lower base probability of developing faults. Moreover, for a heavily worn vehicle, the probability that a breakdown will appear immediately at a major or even critical stage, skipping the minor phases, increases significantly.

> [!NOTE]
> <details>
> <summary><strong>⚙️ Click here for technical details on breakdown probability</strong></summary>
>
> The probability of breakdowns is calculated using a formula designed to create a very noticeable difference between new and heavily-used equipment. Here are the key metrics for a vehicle of average quality:
>
> ### 1. Breakdown Frequency (MTBF)
> The system uses **Mean Time Between Failures (MTBF)** to determine breakdown frequency.
> - **New Vehicle (100% Condition):** The MTBF is **600 minutes (10 hours)**. This means a breakdown occurs, on average, once every 10 operating hours.
> - **Worn-Out Vehicle (0% Condition):** The MTBF drops to **60 minutes (1 hour)**.
>
> ### 2. Critical Failure Chance
> This is the probability that a new breakdown will skip the minor stages and appear immediately as a **critical** failure.
> - **New Vehicle (100% Condition):** The chance is only **5%**.
> - **Worn-Out Vehicle (0% Condition):** The chance rises to **33%**.
>
> ### 3. Lifetime Breakdown Distribution
> This data illustrates how wear impacts long-term reliability. For a vehicle's full lifecycle (100% -> 0% Condition) without any overhauls:
> - **Total Expected Breakdowns:** Approximately **30**.
> - **First Half of Life (100% -> 50% Condition):** Only **~5** breakdowns are expected.
> - **Second Half of Life (50% -> 0% Condition):** The remaining **~25** breakdowns occur as the vehicle's condition rapidly deteriorates.
>
> </details>

#### Stages and Progression
Most breakdowns go through several stages, gradually getting worse:

- **Minor:** A slight decrease in performance that might go unnoticed.

- **Moderate:** Problems become more obvious. Indicators on the dashboard may light up.

- **Major:** Significant operational problems that make using the vehicle difficult.

- **Critical:** Complete failure of a component. The engine stalls, brakes fail, etc.

If not addressed, a breakdown will progress over time. For a vehicle in good condition, this process can take 5-6 operating hours. For a "tired" machine, a breakdown can reach a critical stage in just a couple of hours!

#### Cost and Detection
With each new stage, the cost of repair increases. A critical breakdown can be very costly. For modern vehicles, the mod adds dashboard indicators that usually report a problem starting from the second stage.

#### It Pays to Be Attentive!
The cheapest repair is a preventive one. If you notice that something is "off" with your vehicle (e.g., a slight loss of power) at the first, hidden stage, and immediately take it for an Inspection, you can fix the issue for a minimal price.

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
> The time it takes for a breakdown to advance to the next stage is not static.
> - For a vehicle in good shape (`Condition > 66%`), the average progression time is **5-6 operating hours**.
> - For a heavily worn-out vehicle (`Condition` approaching 0%), this time is reduced by up to **3 times**, meaning a breakdown can become critical much faster.
>
> </details>

#### General Wear and Tear
Beyond random failures, very low condition will trigger a permanent "General Wear and Tear" effect, reducing engine power and braking effectiveness to simulate the sluggishness of old machinery.

> [!NOTE]
> <details>
> <summary><strong>⚙️ Click here for technical details on the "General Wear and Tear" effect</strong></summary>
>
> The "General Wear and Tear" effect begins to apply once a vehicle's `Condition` drops below **66%**. However, its impact is calculated using a cubic formula, meaning the effects are barely noticeable at first but become very significant as the `Condition` approaches zero (especially below 33%).
>
> This effect applies several penalties, which reach their maximum values at 0% `Condition`:
>
> - **Engine Power Reduction:** Up to **-30%**.
> - **Braking Effectiveness Reduction:** Up to **-40%**.
> - **Engine Start Difficulty:** The engine becomes harder to start, especially when cold.
> - **Harvesting Efficiency Loss (for harvesters):** Up to **-20%**, simulating increased crop loss from worn-out components.
>
> </details>

## 3. Workshop Repairs and Service

New options are available to you in the workshop menu:

#### Inspection

- **What it does:** Mechanics perform a full diagnostic. This allows you to detect hidden faults, determine the approximate Condition level, and see if Service is needed.It also generates a performance report, showing you exactly how much power, braking force, or yield has been lost due to "General Wear and Tear" effect.

- **When to use:** Whenever you feel something is "wrong" with the vehicle, or when a warning light is on the dashboard.

#### Maintenance

- **What it does:** Replaces all oils, filters, and fluids. Restores the Service bar to 100%.

- **When to use:** Regularly! However, keep in mind that the cost of this procedure is **fixed** and does not depend on the actual Service level. This means servicing a vehicle at 90% costs the same as servicing it at 10%, so finding the right balance is key to managing your budget.

Manufacturer's recommendation: Every 5 operating hours. Experienced farmers might find their own balance, but don't delay maintenance for too long.

#### Repair

- **What it does:** Fixes specific, diagnosed breakdowns. You can choose which malfunctions to fix and which to leave for later (e.g., if you're short on cash).

- **When to use:** When you have one or more diagnosed breakdowns that are hindering your work.

#### Overhaul

- **What it does:** The most comprehensive and expensive type of work. It includes:

  - A full Maintenance service.

  - Repair of all existing breakdowns.

  - Partial restoration of the vehicle's Condition (worn parts are replaced).

- **When to use:** For old, heavily worn-out vehicles with low Condition to bring them back to life.

**Important:** This procedure is expensive and does not fully restore Condition to 100%. The amount of condition restored depends on the vehicle's age, its maintainability, and a random factor (repair success).

> [!NOTE]
> <details>
> <summary><strong>⚙️ Click here for technical details on the Overhaul mechanic</strong></summary>
>
> The amount of `Condition` restored during an overhaul is not a fixed value. It is calculated based on several factors, ensuring that bringing an old machine back to life is possible, but never makes it "as good as new."
>
> ### 1. Base Restoration Amount
> The core of the calculation is the percentage of **lost `Condition`** that gets restored. This value is randomized within a specific range, which shifts downward as the vehicle gets older.
>
> - **For a new vehicle (up to 1 year old):** The overhaul will restore between **50% and 80%** of the `Condition` that has been lost.
>   - *Example: A vehicle with 30% Condition (30% lost) will be restored to somewhere between 65% and 86% Condition.*
>
> - **For a 10-year-old vehicle:** This range shifts down significantly to approximately **20% to 50%** of lost `Condition`.
>
> ### 2. Maintainability Multiplier
> The final amount of restored `Condition` is then multiplied by the vehicle's **Maintainability** rating.
> - A vehicle with high maintainability will receive the full calculated restoration or even a slight bonus.
> - A vehicle with low maintainability (e.g., a complex, modern machine) will have the restored amount reduced, making overhauls less effective.
>
> ### 3. Aftermarket Parts Risk
> Choosing to perform an overhaul with cheaper **Aftermarket Parts** introduces an additional risk to the restoration quality.
> - This option **halves the minimum possible restoration amount**. The maximum potential outcome remains the same.
> - *Example: For a new vehicle, the restoration range of **60%-90%** becomes **30%-90%** when using aftermarket parts. You might get a great result, or a very poor one.*
>
> </details>

#### Genuine vs. Aftermarket Parts: A New Strategic Choice

For Maintenance, Repair, and Overhaul procedures, you now have a choice between two types of spare parts, creating a classic risk-reward scenario:

- **🔧 Genuine Parts:** These are the standard, manufacturer-approved components. They are more expensive but guarantee a quality result every time.

- **💸 Aftermarket Parts:** A budget-friendly alternative, costing **50% less** than genuine parts. However, this saving comes with a significant risk.

> [!NOTE]
> <details>
> <summary><strong>⚙️ Click here for technical details on the "Defective Parts" mechanic</strong></summary>
>
>
> **The Risk of Defective Parts**
>
> 
> Every time you use Aftermarket Parts, there is a **1 in 3 chance (≈33%)** that they are of poor quality. If you are unlucky, a random negative effect (debuff) will be applied to the vehicle for **5 operating hours**:
> - **Increased Maintenance Wear:** The `Service` level will decrease 50% faster.
> - **Increased Condition Wear:** The vehicle's `Condition` will decrease 50% faster.
> - **Increased Breakdown Chance:** The probability of a random breakdown is doubled.
> 
> </details>

This choice adds another strategic layer: do you save money now and risk future problems, or do you pay for reliability?

#### ⏱️ Time and Planning: A New Layer of Strategy
Beyond money, all workshop procedures require time. The duration of a service or repair depends on the vehicle's Maintainability (simpler machines are fixed faster).

 **Important:** The workshop has operating hours. All work is paused overnight and resumes only when the workshop opens the next day.
 
 This adds a new layer of strategy: you now need to plan when to take your vehicles in for service. An urgent repair on a combine during the harvest season might extend into the next day, leading to downtime and financial loss.

## 4. Vehicle Characteristics: Reliability and Maintainability

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
> For most brands, the values for both **Reliability** and **Maintainability** typically range from **`0.8`** (less reliable/maintainable) to **`1.2`** (very reliable/maintainable), with rare exceptions.
>
> ### Production Year Bonus
> The **Maintainability** rating also receives a bonus based on the vehicle's production year.
> - If a vehicle was produced **before the year 2000**, it receives a bonus to its maintainability rating. This simulates the simpler construction and electronics of older machinery, resulting in cheaper and faster service.
>
> ### Configuration File
> All brand-specific values for `Reliability` and `Maintainability` can be viewed and even customized in the `ADS_Config.lua` file, located in the mod's folder.
>
> </details>
