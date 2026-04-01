# FS25_AdvancedDamageSystem

Advanced Damage System is a mod that completely reworks the standard vehicle damage and maintenance system in Farming Simulator 25. A machine's reliability now depends directly on how carefully and efficiently you use it: the harder you push your equipment and the worse you maintain it, the more often it will break down.

Forget about one-click repairs. Maintenance now takes time, resources, and proper planning. You will need to manage wear, schedule repairs in advance, and organize your fleet so that breakdowns do not ruin the season.

<table>
<tr>
<td width="65%" valign="top">

> [!WARNING]
> **IMPORTANT WARNING**
>
> *   This mod is a work in progress (WIP). Features are subject to change, and bugs are to be expected.
> *   Use at your own risk. The author is not responsible for any potential issues with your savegame or game. It is strongly recommended to back up your saves.

</td>
<td width="35%" align="center" valign="top">
<img width="256" height="256" alt="icon_ads" src="https://github.com/user-attachments/assets/ac09c1b1-daa3-4026-b312-b09156d9a03e" />

</td>
</tr>
</table>

# Acknowledgements 

A huge thank you to **Frvetz** (https://github.com/Frvetz), creator of the Realistic Damage System mod for FS22, for the permission to use ideas from his mod and for the support during the early stages of development.

A huge special thanks to Squallqt (https://github.com/Squallqt) for his direct contributions to the project. He implemented multiplayer support and provided invaluable help with testing and technical advice.

Also, a big thank you to **Derwen Modding** for testing the early builds.

# Key Features
- **Complete Replacement of the Vanilla Damage System:** Every vehicle in the game is now divided into multiple individual systems: engine, transmission, hydraulics, cooling system, fuel system, working systems, electrical system, and chassis. Each system tracks how the machine is actually being used. For example, chassis wear increases faster if you drive quickly over rough terrain. The harsher the operating conditions, the faster wear builds up and the more often breakdowns occur.
- **Regular Maintenance Becomes Essential:** Scheduled service is now required to prevent accelerated wear and avoid costly failures.
- **Dynamic Breakdowns:** Dozens of different failures tied to specific systems, each with its own gameplay effects and consequences.
- **Fully Reworked Workshop Menu and Logic:** The workshop now supports inspection, repair, maintenance, and overhaul. Each procedure has configurable options and takes time to complete, so there is no one-click repair.
- **Realistic Thermal Simulation:** Engines need proper warm-up, and they can overheat under heavy load in hot conditions. Ignoring temperature can lead to serious consequences.
- **Realistic Battery and Alternator Simulation:** The battery can now discharge, and the alternator can fail, leading to difficult engine starts. However, you can always jump-start a vehicle from another machine.
- **Vehicle-Specific Characteristics:** Vehicles differ by brand and production year in Reliability (affecting wear rate, breakdown probability, and service intervals) and Maintainability (affecting service cost and service time). Premium brands are generally more reliable than budget alternatives, while older machines are often mechanically simpler and therefore more maintainable.
- **Pre-Operation Inspection:** Before heading to the field, vehicles need to be inspected and serviced at the start of each shift: greasing components, blowing out the radiator and air intakes, and carrying out other essential routine procedures.

  ... More information below in the guide

Demonstration of some breakdown's effects: https://www.youtube.com/watch?v=NpnlvY25Xl0&list=PL73V6HaxZ69gRgpLGkHpb_k5Qh1w4ZtHa

# Console Commands
For testing and debugging, ADS includes console commands. Most commands require you to be inside a vehicle that supports this mod.

| Command | Description | Usage Example |
| --- | --- | --- |
| **ads_debug** | Toggles ADS debug mode on/off. | `ads_debug` |
| **ads_listBreakdowns** | Lists all available breakdown IDs from the registry. | `ads_listBreakdowns` |
| **ads_addBreakdown** | Adds a breakdown to the current vehicle. Optional arguments: breakdown ID and stage. | `ads_addBreakdown ECU_MALFUNCTION 2` |
| **ads_removeBreakdown** | Removes a specific breakdown from the current vehicle. If no ID is provided, all active breakdowns are removed. | `ads_removeBreakdown ECU_MALFUNCTION` |
| **ads_advanceBreakdown** | Advances a specific active breakdown to the next stage. If no ID is provided, all active breakdowns are advanced where possible. | `ads_advanceBreakdown ECU_MALFUNCTION` |
| **ads_setCondition** | Sets the Condition value for all enabled systems on the current vehicle (`0.0`-`1.0`). | `ads_setCondition 0.5` |
| **ads_setSystemCondition** | Sets Condition for one specific system on the current vehicle (`0.0`-`1.0`). | `ads_setSystemCondition engine 0.75` |
| **ads_setSystemStress** | Sets Stress for one specific system on the current vehicle (`>= 0.0`). | `ads_setSystemStress electrical 0.25` |
| **ads_setSystemStressMultiplier** | Sets the stress accumulation multiplier for one system, or for all systems if no system is specified. | `ads_setSystemStressMultiplier 12 electrical` |
| **ads_setService** | Sets the current vehicle's Service level (`0.0`-`1.0`). | `ads_setService 0.2` |
| **ads_resetVehicle** | Fully resets the current vehicle state: condition, service, and active breakdowns. | `ads_resetVehicle` |
| **ads_startService** | Starts service on the current vehicle. Types: `inspection`, `maintenance`, `repair`, `overhaul`. With `repair`, optional `[count]` selects how many visible breakdowns to repair. | `ads_startService repair 2` |
| **ads_finishService** | Instantly finishes the currently active service on the current vehicle. | `ads_finishService` |
| **ads_getServiceState** | Prints the current workshop and service state variables for the current vehicle. | `ads_getServiceState` |
| **ads_showServiceLog** | Prints the vehicle's service log. Optional `[index]` shows one entry in detailed form. | `ads_showServiceLog 1` |
| **ads_getDebugVehicleInfo** | Prints detailed debug information about the current vehicle. Optional argument also lists attached specializations. | `ads_getDebugVehicleInfo 1` |
| **ads_setDirtAmount** | Sets the current vehicle's dirt level (`0.0`-`1.0`). | `ads_setDirtAmount 0.8` |
| **ads_setFuelLevel** | Sets the current vehicle's fuel level using either a `0.0`-`1.0` value or `0`-`100` percent. | `ads_setFuelLevel 25` |
| **ads_resetFactorStats** | Resets the accumulated factor statistics for the current vehicle. | `ads_resetFactorStats` |
| **ads_toggleHudDebugView** | Switches the ADS HUD debug view between normal and factor stats modes. | `ads_toggleHudDebugView stats` |
| **ads_setConfigVar** | Changes a value inside `ADS_Config` at runtime. Intended for testing and debugging. | `ads_setConfigVar CORE.BASE_SYSTEMS_WEAR 0.02` |
| **ads_setSpecVar** | Changes a value inside `spec_AdvancedDamageSystem` on the current vehicle. Intended for testing and debugging. | `ads_setSpecVar systems.engine.condition 0.85` |

# Screenshots
<img width="2560" height="1440" alt="444" src="https://github.com/user-attachments/assets/4286276b-d204-4166-886f-4eebe964fba9" />
<img width="1907" height="1308" alt="666" src="https://github.com/user-attachments/assets/aaa4f359-e4cb-4c77-857a-6e3af5a00304" />
<img width="1314" height="839" alt="111" src="https://github.com/user-attachments/assets/66e7e049-59e6-4f26-937a-a74f1e19a247" />
<img width="2381" height="1358" alt="image" src="https://github.com/user-attachments/assets/f33415b6-c38f-4de8-8b3f-4c858adeabe0" />
<img width="1253" height="763" alt="image" src="https://github.com/user-attachments/assets/18fe2f51-44f8-46fe-a1ac-8b892d25852c" />
<img width="1233" height="832" alt="222" src="https://github.com/user-attachments/assets/64748b85-6e3c-43d6-b19a-d7027e66df49" />
<img width="1334" height="788" alt="Снимок экрана 2026-03-29 224955" src="https://github.com/user-attachments/assets/77ca8ae3-a531-4934-96d0-b53c941e5095" />


# Mod Guide
The Advanced Damage System (ADS) mod completely replaces the standard damage system, offering a deep and detailed simulation of wear, breakdowns, and technical service.
This guide will help you understand all aspects of the mod.


## 1. Core Mechanics: Condition, Stress and Service

Each vehicle can contain all or only some of the following systems: engine, transmission, hydraulics, cooling system, fuel system, working systems, electrical system, and chassis. Every system has two key parameters: `Condition` and `Stress`.

### ⚙️ Condition

This is the main indicator of a system's health and remaining service life.

- **What does Condition affect?**
Condition determines how resistant a system is to breakdowns. As Stress builds up through poor or demanding operation, the Condition value defines the threshold at which breakdown risk becomes critical. In simple terms: the lower the Condition, the less abuse the system can take before it starts to fail.

- **How does it decrease?**
Condition decreases as the vehicle is used. With the default settings, this is roughly `1%` per hour under normal operation. However, harsh or improper use increases wear significantly, and each system has its own factors that accelerate deterioration. Condition also decreases very slowly over time if the vehicle is stored outdoors instead of under cover.

- **How to restore Condition?**
Condition can be partially restored through the `Overhaul` procedure in the workshop. You can restore individual systems or rebuild several systems at once.

### ⚠️ Stress

This is the accumulated result of misuse, overload, and operating mistakes that a system suffers during vehicle use.

- **What does Stress affect?**
Stress directly affects the probability of failures appearing in a specific system. The higher the Stress, the higher the breakdown risk. The upper limit of Stress, where the probability becomes critical, is the current `Condition` value of that system.

- **How does it increase?**
Stress does not build up during normal operation. It increases only through improper use: overload, overheating, running a cold machine under load, wheel slip, harsh working conditions, and other mistakes specific to each system.

- **How to reduce Stress?**
Stress can be reduced through preventive maintenance in the workshop. In addition, Stress is automatically lowered after a breakdown occurs. Repairs also give you options: a standard repair significantly reduces Stress, while a full repair with replacement of adjacent components removes all Stress from the system.


### 💧 Service

This parameter reflects the state of consumables: oil, filters, technical fluids, etc.

- **What does Service affect?**
This is a critically important parameter. A low Service level significantly accelerates the decline of Condition in every system, but not all systems are affected equally. For example, the engine suffers much more from overdue service than the cooling system. Timely maintenance is the best way to save money on expensive repairs in the future.

- **How does it decrease?**
It decreases with engine operating hours, simulating the natural wear of consumables.

- **How to restore it?**
It is restored to 100% through the Maintenance procedure in the workshop (depending on the selected maintenance scope, this value can be lower or higher).


### A Note on Player Knowledge: Hidden Values
You can check overall `Condition`, system `Condition`, system `Stress`, and `Service` in the workshop by running an Inspection. In most cases, the result is an approximate status (for example: Service is `OPTIMAL`, `NOT REQUIRED`, `REQUIRED`, or `OVERDUE`).

Exact percentage values are available only through a full diagnostic (defectoscopy) procedure, which is expensive and time-consuming.

In practice, this level of precision is usually unnecessary. A responsible farmer follows the manufacturer-recommended service interval for each machine, performs maintenance on schedule, and when the time comes, either carries out an overhaul or replaces the vehicle.

## 2. Wear Factors

Each system has its own set of wear factors that accelerate `Condition` loss and increase `Stress`. At the same time, there are several global factors that can affect multiple systems at once:

- **Service Factor:** The effect of overdue maintenance. The longer the service interval is overdue, the stronger this factor becomes.

- **Breakdown Presence Factor:** An active breakdown in a system accelerates the wear of its remaining components.

- **Idle Factor:** If a system is not being actively used, its wear rate is significantly reduced. For example, the transmission experiences very little wear while the vehicle is not moving.

- **Downtime Factor:** A small passive wear effect that applies when the vehicle is not running and is stored outdoors.

### Engine

- **Motor Overload Factor:** Triggers when engine load exceeds `90%`. The effect becomes stronger as load gets closer to `100%`.

- **Air Intake Clogging Factor:** Triggers when air intake clogging exceeds `50%`. The effect becomes stronger as clogging increases.

- **Cold Engine Factor:** Triggers when engine temperature is below `50C` and RPM load is above `75%`. This factor does not apply to AI vehicles.

- **Overheated Engine Factor:** Triggers when engine temperature is above `95C` and engine load is above `30%`. The effect becomes stronger as temperature and load increase.

### Transmission

- **Pull Overload Factor:** Triggers when engine load is above `82%` and the vehicle is moving faster than `0.5 km/h`. The effect builds up over time and reaches its maximum after `30` seconds of continuous overload.

- **Lugging Factor:** Triggers when engine load is above `80%`, RPM load is below `80%`, and the vehicle is moving faster than `0.5 km/h`. The effect becomes stronger as the gap between load and RPM increases.

- **Wheel Slip Factor:** Triggers when wheel slip exceeds `30%`. The effect becomes stronger as slip increases.

- **Cold Transmission Factor:** Applies only to CVT transmissions. Triggers when transmission temperature is below `50C` and RPM load is above `75%`. This factor does not apply to AI vehicles.

- **Overheated Transmission Factor:** Applies only to CVT transmissions. Triggers when transmission temperature is above `95C` and engine load is above `30%`. The effect becomes stronger as temperature increases.

- **Heavy Trailer Factor:** Activates when the mass of the towed trailer exceeds the tractor's own mass by more than `1.2x`.

### Hydraulics

- **Operating Factor:** Triggers during active hydraulic work. The effect becomes stronger as the working mass ratio increases.

- **Heavy Lift Factor:** Triggers when lifted mass exceeds `30%` of the vehicle's mass. The effect becomes stronger as lifted mass increases.

- **Cold Oil Factor:** Triggers during active hydraulic work when engine temperature is below `30C`. The effect becomes stronger as temperature gets lower.

- **PTO Operation Factor:** Triggers when the PTO is active. In the current config, this factor is set to `0`, so it currently has no effect.

- **Sharp PTO Angle Factor:** Triggers when the connected PTO angle exceeds `20` degrees. The effect becomes stronger as the angle increases.

### Cooling

- **High Cooling Load Factor:** Triggers when thermostat state exceeds `90%`. The effect becomes stronger as cooling effort increases.

- **Overheat Factor:** Triggers when engine temperature exceeds `95C`. The effect becomes stronger as temperature increases.

- **Cold Shock Factor:** Triggers when engine temperature is below `50C` and RPM load is above `75%`. This factor does not apply to AI vehicles.

### Electrical

- **Lights Usage Factor:** Triggers when the main lights are on.

- **Weather Exposure Factor:** Triggers when the vehicle is outdoors during rain, snow, or hail.

- **Cranking Stress Factor:** Triggers while the starter is engaged.

- **Overheat Factor:** Triggers when engine temperature exceeds `95C`.

### Chassis

- **Vibration Factor:** Triggers when the vibration signal exceeds its threshold. The effect becomes stronger at higher speed and on rougher surfaces.

- **Steering Load Factor:** Triggers at speeds up to `4 km/h` when the steering input is active and changing while the wheels have ground contact. The effect becomes stronger with sharper steering input.

- **Brake Mass Factor:** Triggers during braking above `2 km/h` when total vehicle mass is greater than its own mass. The effect becomes stronger with heavier mass and stronger braking input.

### Fuel

- **Low Fuel Starvation Factor:** Triggers when fuel level drops below `20%`. The effect becomes stronger as fuel level gets lower and engine load increases.

- **Cold Fuel Factor:** Triggers when fuel temperature is below `20C` and engine load is above `50%`. The effect becomes stronger as temperature gets lower.

- **Idle Deposit Factor:** Triggers after `60` seconds of idling. The effect continues to grow up to `600` seconds of idling.

- **High Pressure Factor:** Triggers when engine load exceeds `90%`. The effect becomes stronger as load gets closer to `100%`.

### Work Process

- **Long Operation Factor:** Triggers whenever the machine is turned on. The effect grows with continuous operation and reaches its maximum after `7200` seconds.

- **Wet Crop Factor:** Triggers when the machine is turned on, harvesting is in progress, and the weather is wet.

- **Lubrication Factor:** Triggers when the machine requires lubrication and lubrication level is below `50%`. The effect becomes stronger as lubrication level drops.

## 3. Breakdowns

In ADS, your vehicles can suffer real breakdowns. Some failures are minor and only reduce performance, while others can make the machine completely inoperable.

> [!NOTE]
> <details>
> <summary><strong>📋 Click here for a full list of breakdowns and their effects</strong></summary>
> 
> This is a comprehensive list of all selectable (random) breakdowns in the mod. Each breakdown has several stages, with the effects becoming more severe over time. The "Critical Effect" listed is the final stage of the malfunction.
>
> ---
> 
> ### ⚡ Electrical Systems
>
> #### ECU Malfunction
> * *Applicable to:* Modern non-electric vehicles (`Year 2000+`).
> * *Symptoms:* ECU errors cause reduced engine power, increased fuel consumption, dark exhaust smoke, and at advanced stages can lead to stalls and difficult starting.
> * *Critical Effect:* **Complete ECU failure.** The engine can no longer be controlled and will not start.
>
> #### Corroded Wiring
> * *Applicable to:* Modern vehicles (`Year 2000+`) equipped with lights.
> * *Symptoms:* Flickering or failed lights, unstable voltage supply, hard starting, occasional stalls, and loss of power in critical circuits.
> * *Critical Effect:* **Starter control circuit failure.** Lighting is inoperative and engine start is impossible.
>
> #### Battery Sulfation
> * *Applicable to:* All vehicles.
> * *Symptoms:* Reduced effective battery capacity, weak electrical reserve under load, unstable cranking, and progressively harder engine starts.
> * *Critical Effect:* **Battery capacity is almost gone.** Cranking performance becomes too weak for reliable starting.
>
> #### Alternator Regulator Failure
> * *Applicable to:* All vehicles.
> * *Symptoms:* Reduced or unstable charging output, poor battery charging, voltage losses, and a steadily weakening electrical system.
> * *Critical Effect:* **No battery charging.** The vehicle runs only on the remaining battery reserve.
>
> ---
>
> ### ⚙️ Engine Systems
>
> #### Turbocharger Wear
> * *Applicable to:* Currently only enabled for the `Fiat 160-90 DT`.
> * *Symptoms:* Turbo whistle, noticeable power loss at high RPM, rising fuel consumption, and possible engine stalls under heavy load.
> * *Critical Effect:* **Catastrophic turbo failure.** The engine loses most of its power and is at serious risk of further damage.
>
> #### Oil Pump Malfunction
> * *Applicable to:* All non-electric vehicles.
> * *Symptoms:* Low oil pressure, reduced engine torque, rising engine temperature, mechanical knocking, and possible stalling as the failure worsens.
> * *Critical Effect:* **Critical oil circulation failure.** Safe engine operation and reliable starting are no longer possible.
>
> #### Valve Train Malfunction
> * *Applicable to:* All non-electric vehicles.
> * *Symptoms:* Reduced engine torque, increased fuel consumption, abnormal valve train noise, hesitation under load, and possible stalls.
> * *Critical Effect:* **Valve train failure.** The engine can no longer operate correctly and may not start at all.
>
> ---
>
> ### ⚙️ Transmission Systems
>
> #### Manual Transmission Clutch Wear
> * *Applicable to:* Vehicles with manual transmissions.
> * *Symptoms:* Transmission slip under load, weak power delivery to the wheels, and increasing fuel consumption as clutch wear progresses.
> * *Critical Effect:* **Clutch burnout.** The vehicle is unable to move.
>
> #### Transmission Synchronizer Malfunction
> * *Applicable to:* Vehicles with manual or synchro-shift transmissions, excluding Powershift.
> * *Symptoms:* Grinding noises, difficult shifts, failed gear changes, and gear rejection under load.
> * *Critical Effect:* **Synchronizer failure.** Shifting gears becomes impossible.
>
> #### Powershift Hydraulic Pump Malfunction
> * *Applicable to:* Vehicles with Powershift transmissions.
> * *Symptoms:* Delays, harsh engagement, and violent shocks during gear changes as hydraulic pressure drops.
> * *Critical Effect:* **Hydraulic pump failure.** The transmission is stuck in neutral.
>
> #### CVT Chain Wear
> * *Applicable to:* Vehicles with CVT transmissions.
> * *Symptoms:* Variator slip, higher fuel consumption, rising transmission temperature, and worsening torque transfer.
> * *Critical Effect:* **Critical CVT chain wear.** Reliable vehicle movement can no longer be guaranteed.
>
> #### CVT Hydraulic Control Valve Malfunction
> * *Applicable to:* Vehicles with CVT transmissions.
> * *Symptoms:* Hydraulic pressure drops, reduced engine torque, restricted ratio range, rising transmission heat, and unstable CVT operation.
> * *Critical Effect:* **Control valve failure.** The transmission falls into a severely restricted emergency mode.
>
> ---
>
> ### 🛠️ Hydraulic Systems
>
> #### Hydraulic Pump Malfunction
> * *Applicable to:* Most non-truck, non-passenger hydraulic vehicles from `1960+`.
> * *Symptoms:* Hydraulic implements become progressively slower, weaker, and less responsive.
> * *Critical Effect:* **Hydraulic pump failure.** The hydraulic system becomes inoperable.
>
> #### Hydraulic Cylinder Internal Leak
> * *Applicable to:* Most non-truck, non-passenger hydraulic vehicles from `1960+`.
> * *Symptoms:* Slower hydraulic movement, weak actuation, and attached implements drifting or failing to hold position under load.
> * *Critical Effect:* **Critical internal leakage.** Hydraulic movement is almost lost and load holding is no longer possible.
>
> #### PTO Clutch Slip
> * *Applicable to:* Vehicles with PTO capability.
> * *Symptoms:* Reduced PTO torque transfer and frequent automatic PTO disengagement under load.
> * *Critical Effect:* **PTO clutch failure.** PTO operation is no longer possible.
>
> ---
>
> ### 🚜 Chassis Systems
>
> #### Brake Malfunction
> * *Applicable to:* Wheeled vehicles.
> * *Symptoms:* Reduced braking force, longer stopping distances, weak braking response, and dangerous loss of braking effectiveness.
> * *Critical Effect:* **Brake system failure.** Braking becomes impossible.
>
> #### Bearing Wear
> * *Applicable to:* Wheeled vehicles.
> * *Symptoms:* Bearing noise, vibration, increased rolling resistance, lower maximum speed, and rising drivetrain load.
> * *Critical Effect:* **Wheel bearing seizure.** Wheel rotation is blocked.
>
> #### Steering Linkage Wear
> * *Applicable to:* Wheeled vehicles without tracks.
> * *Symptoms:* Steering pull, reduced steering response, poor directional stability, and increasingly unreliable control.
> * *Critical Effect:* **Steering linkage failure.** Safe directional control can no longer be ensured.
>
> #### Track Tensioner Malfunction
> * *Applicable to:* Tracked vehicles only.
> * *Symptoms:* Directional pull, vibration, drag noise, extra drivetrain load, reduced speed, and unstable track running.
> * *Critical Effect:* **Track tensioner failure.** The running gear can seize.
>
> ---
>
> ### 🌡️ Cooling Systems
>
> #### Thermostat Malfunction
> * *Applicable to:* All non-electric vehicles.
> * *Symptoms:* Slow warm-up or unstable temperature regulation at first, followed by persistent overheating under load.
> * *Critical Effect:* **Thermostat failure.** Coolant circulation is disrupted and severe overheating becomes unavoidable.
>
> #### Coolant Leak
> * *Applicable to:* All non-electric vehicles.
> * *Symptoms:* Reduced cooling efficiency, faster temperature rise under load, and an increasing likelihood of overheating.
> * *Critical Effect:* **Critical coolant loss.** Safe engine temperature can no longer be maintained.
>
> #### Fan Clutch Failure
> * *Applicable to:* All non-electric vehicles.
> * *Symptoms:* Reduced fan efficiency, abnormal fan clutch noise, weak airflow through the cooling pack, and a high overheating risk.
> * *Critical Effect:* **Fan clutch failure.** Adequate cooling airflow is no longer possible.
>
> ---
>
> ### ⛽ Fuel Systems
>
> #### Fuel Pump Malfunction
> * *Applicable to:* All non-electric vehicles.
> * *Symptoms:* Rough idle, reduced power, higher fuel consumption, hesitation, difficult starting, and frequent stalls as fuel pressure drops.
> * *Critical Effect:* **Fuel pump failure.** Fuel is no longer supplied to the engine.
>
> #### Fuel Injector Malfunction
> * *Applicable to:* All non-electric vehicles.
> * *Symptoms:* Rough running, hesitation under load, reduced power, higher fuel consumption, and increasingly unreliable starting.
> * *Critical Effect:* **Injector failure.** The engine will not run correctly and may not start at all.
>
> #### Fuel Filter Clogging
> * *Applicable to:* All non-electric vehicles.
> * *Symptoms:* Restricted fuel flow, hesitation under load, lower engine torque, and possible engine stalls.
> * *Critical Effect:* **Critical filter blockage.** Fuel flow becomes insufficient for engine operation.
>
> #### Fuel Line Air Leak
> * *Applicable to:* All non-electric vehicles.
> * *Symptoms:* Unstable fuel supply, difficult starting, hesitation, and engine stalls caused by air entering the system.
> * *Critical Effect:* **Critical air leak.** The engine cannot maintain fuel supply and will not run reliably.
>
> ---
>
> ### 🌾 Work Process Systems
>
> #### Harvest Processing System Wear
> * *Applicable to:* Combines, cotton harvesters, rice harvesters, vine harvesters, and related harvesting machines.
> * *Symptoms:* Reduced crop processing efficiency and progressively increasing yield loss during harvesting.
> * *Critical Effect:* **Critical processing wear.** Yield loss becomes extreme during operation.
>
> #### Unloading Auger Malfunction
> * *Applicable to:* Combines with unloading auger systems.
> * *Symptoms:* Progressive unloading slowdown caused by belt, pulley, or gearbox wear in the auger drive.
> * *Critical Effect:* **Unloading auger failure.** Grain unloading becomes unavailable until repaired.
> 
> </details>

#### Chance and Severity of Breakdowns
The probability of a breakdown depends entirely on the `Stress` level in a specific system. The closer the current `Stress` is to that system's current `Condition`, the higher the chance of a failure occurring.

In addition, the `Condition` level determines the probability of a critical breakdown. A critical breakdown is a failure that appears immediately at `Stage 4`, skipping the earlier stages. The lower a system's `Condition`, the higher the chance that a breakdown will be critical from the start.

The type of breakdown is not entirely random. First, it will always belong to the damaged system. Second, ADS keeps track of which wear factors have been active most often and uses that history to determine which failure is most likely to occur.

#### Stages and Progression
Most breakdowns go through several stages, gradually getting worse:

- **Minor:** A slight decrease in performance that might go unnoticed.

- **Moderate:** Problems become more obvious. Indicators on the dashboard may light up.

- **Major:** Significant operational problems that make using the vehicle difficult.

- **Critical:** Complete failure of a component. The engine stalls, brakes fail, etc.

The stage at which a breakdown first appears depends on the system's `Condition`. The lower the `Condition`, the higher the starting stage is likely to be.

If not addressed, a breakdown will progress over time and can advance to a more severe stage. Progression is context-dependent: each breakdown has its own progression conditions. For example, unloading-system faults on combines progress only while the machine is unloading crop, which is intentionally modeled this way for realism.

#### Cost and Detection
With each new stage, the cost of repair increases. A critical breakdown can be very costly. For modern vehicles, the mod adds dashboard indicators that usually report a problem starting from the second stage.

#### It Pays to Be Attentive!
The cheapest repair is a preventive one. Keep an eye on—and an ear out for—your equipment. The initial stages of a breakdown are accompanied by various visual and audio cues that serve as early warning signs. This might manifest as fluctuating engine RPMs, dark exhaust smoke, or other unusual noises like knocking or squeaking during operation. If you catch these symptoms during the first, hidden stage and promptly take your vehicle for an Inspection, you can fix the problem for a minimal price.

#### General Wear and Tear
In addition to having a higher chance of breakdowns, older vehicles also suffer from gradual degradation of their core performance. As wear accumulates, engine power may drop, the transmission may begin to slip, battery performance may weaken, cooling efficiency may decline, and other important characteristics may deteriorate.

The closer a vehicle gets to the end of its service life, the more noticeable these degradation effects become. Even without a specific breakdown, a worn machine will already perform worse, less consistently, and less efficiently.
Beyond random failures, low condition can trigger a permanent "General Wear and Tear" effect, simulating the sluggishness and aging behavior of worn machinery.


## 4. Workshop Repairs and Service

The workshop system has been fully reworked. You now choose between four core procedures: **Inspection**, **Maintenance**, **Repair**, and **Overhaul**.

You can also configure additional service parameters. For example, you can choose part quality (**Used**, **Aftermarket**, **OEM**, **Premium**) or set the desired maintenance scope.

These options directly affect service **duration**, **cost**, and **quality**. All procedures now take meaningful time, so maintenance planning is an important part of fleet management.

#### Inspection

- **What it does:** Helps you detect faults and understand the current condition of the vehicle. The quality of fault detection and the level of detail in the report depend on the selected inspection type:

  - **Visual Inspection:** A quick external check for when time is short. It can detect breakdowns, but because of the limited scope, there is a small chance that something important will be missed.

  - **Standard Inspection:** A standard full inspection procedure. It detects faults and generates a standard condition report for the vehicle.

  - **Complete Defectoscopy:** A complete technical defectoscopy of the vehicle. It can detect even hidden and potential breakdowns, identify defective parts, and generates a comprehensive report with exact condition values for vehicle systems.

- **When to use:** Use it when you suspect a problem, when warning indicators appear, before expensive repairs, or when you want a clear picture of the vehicle's condition.

#### Maintenance

- **What it does:** Replaces all oils, filters, and fluids, restores your vehicle's `Service` level, and also performs a standard inspection. The result depends on the selected maintenance scope:

  - **Minimal:** Basic service. Significantly cheaper and faster, but does not fully restore the `Service` level. A great choice when time is short and you just need to finish the season.

  - **Standard:** Routine maintenance according to manufacturer specifications. Restores `Service` to a normal level.

  - **Extended:** Comprehensive service. Takes longer and costs more, but restores `Service` above the standard level. An ideal choice for long campaigns.

  - **Preventive:** Preventive maintenance beyond the standard manufacturer service. Restores `Service` to a normal level and reduces `Stress` in the most problematic systems. It is expensive and time-consuming, but it significantly lowers the risk of breakdowns. An ideal choice for players who do not like unpleasant surprises in the middle of the season.

- **When to use:** Regularly. Depending on its quality, each vehicle has its own service interval recommended by the manufacturer, and it should be followed closely. Small delays will not lead to immediate disaster, but if you ignore maintenance for too long, breakdowns will start to appear and the overall condition of the vehicle will decline rapidly. Also keep in mind that the cost of this procedure is **fixed** and does not depend on the actual `Service` level. This means servicing a vehicle at `90%` costs the same as servicing it at `10%`, so finding the right balance is key to managing your budget.


#### Repair

- **What it does:** As the name suggests, repair removes detected breakdowns or makes them temporarily inactive. In addition, repair can also reduce the `Stress` level in the affected system.

  Repair is available in three types:

  - **Quick Fix:** A fast and almost free procedure that removes the negative effects of a breakdown on the vehicle, but does not eliminate the fault itself. The fault will return after some time. A service for specific situations when time is extremely limited.

  - **Standard:** Standard repair with replacement of the failed part. Fully removes the fault and significantly reduces `Stress` in the system.

  - **Advanced:** Comprehensive repair with replacement of all related parts around the failed component. Fully removes all consequences of the breakdown and reduces system `Stress` to zero.

- **When to use:** Always when something has broken.


#### Overhaul

- **What it does:** The most expensive and time-consuming type of work, capable of bringing old machinery back to life. Overhaul can:

  - restore the `Condition` of one system or all systems;

  - reduce `Stress` to zero in one or several systems;

  - repair all breakdowns in one system or in the whole vehicle;

  - perform maintenance as part of the procedure, unless it is a partial overhaul.

  For an additional fee, you can also renew the vehicle's paintwork at a much lower cost than a normal repaint.

  Overhaul comes in three variants:

  - **Partial:** A partial overhaul that works on one selected system. Restores that system's `Condition` to a good level.

  - **Standard:** A standard overhaul for the whole vehicle. Restores all systems to a good level.

  - **Full** or **Factory Restoration:** A very long and expensive procedure, comparable in cost to buying another machine. Brings the vehicle back to an almost like-new state and restores system `Condition` to an excellent level.

- **When to use:** For old, heavily worn-out vehicles with low Condition to bring them back to life.

**Important:** This procedure is expensive and does not restore `Condition` to a fixed `100%`. The final restoration level depends on vehicle maintainability, the number of previous overhauls, and a random restoration factor.


#### Parts Quality Options

For **Maintenance** and **Repair**, you can choose between four part qualities:

- **Used** (`Used`)
- **Budget analogs** (`Aftermarket`)
- **Original parts** (`OEM`)
- **Premium parts** (`Premium`)

These options differ by cost and defect probability. The cheaper the parts, the higher the chance that they will be defective.

Depending on the procedure, defective parts have different negative effects. During **Maintenance**, defective or low-quality consumables significantly shorten the service interval and increase `Condition` wear across vehicle systems. During **Repair**, low-quality parts may fail again after some time and bring the same fault back.

**Complete Defectoscopy** can detect defective parts and poor-quality consumables.


#### ⏱️ Time and Planning
Beyond money, all workshop procedures require time. The duration of a service or repair depends on the vehicle's Maintainability (simpler machines are fixed faster).

 **Important:** The workshop has operating hours. All work is paused overnight and resumes only when the workshop opens the next day.
 
 This adds a new layer of strategy: you now need to plan when to take your vehicles in for service. An urgent repair on a combine during the harvest season might extend into the next day, leading to downtime and financial loss.

## 5. Reliability and Maintainability

Each brand of vehicle in the game now has two parameters based on its real-world reputation:

#### ✅ Reliability

- **What it is**: Shows how well-made the vehicle is. Displayed with a checkmark icon in the shop menu.

- **What it affects:** A vehicle with high reliability loses Condition more slowly, has a lower base probability of random breakdowns and has longer service intervals

Examples: Premium European and American brands are generally more reliable than budget or older Eastern European counterparts.

#### 🔧 Maintainability

- **What it is:** Shows how easily and cheaply the vehicle can be serviced and repaired.

- **What it affects:** A vehicle with high maintainability requires less money and time for all workshop operations and restores its Condition better after an overhaul.

Examples: Simple, older vehicles are often more maintainable than modern machines packed with electronics.

## 6. Thermal Dynamics
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

## 7. Alternator & Battery

ADS simulates the vehicle electrical system as a real working model rather than a simple on/off mechanic. The mod tracks battery charge, alternator output, onboard electrical loads, battery temperature, internal resistance, and voltage behavior under charging and discharge.

Battery behavior depends on several factors at once. Its available capacity drops in cold weather, internal resistance rises as the battery gets colder and more worn, and charge acceptance is reduced not only by low temperature, but also by high state of charge and poor battery health. In practice, this means a weak or cold battery does not just "have less charge" - it also charges worse, sags harder under load, and performs noticeably worse during starting.

The alternator is also modeled dynamically. Its output depends on engine RPM, current electrical load, and alternator health. If the onboard consumers demand more current than the alternator can provide, system voltage starts to sag and the battery begins to discharge. If there is charging headroom, the battery recharges gradually rather than instantly, and the charging process is limited by its real acceptance capability.

Battery temperature is simulated separately. It is influenced by ambient temperature, engine bay heat, and self-heating from current flowing through the battery's internal resistance. Because of that, the same battery can behave very differently in winter, after a cold start, or after long operation under heavy electrical load.

This system also interacts with breakdowns. A failed alternator can leave the machine running only on battery reserve, while battery failure can lead to weak cranking, hard starting, or a complete no-start situation. Depending on the condition of the electrical system, the vehicle may suffer from unstable voltage, poor charging, or total loss of starting ability.

If the battery is too weak to start the engine, you can use jumper cables and get power from another vehicle. ADS models this as an actual external power connection: both batteries are linked into a shared circuit, current flows between them, and the donor vehicle can support the receiver during cranking or temporary charging.
