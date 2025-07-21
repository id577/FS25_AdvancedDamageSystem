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
- Two New Parameters: Condition (overall mechanical wear) and Service (consumables). Poor service accelerates wear, and low condition leads to breakdowns.
- Dynamic Breakdowns: Dozens of malfunctions for the engine, transmission, brakes, and hydraulics. Breakdowns have several stages and progress over time if not addressed.
- Realistic Temperature Simulation: Overheating the engine or transmission reduces power or leads to critical failure on older equipment.
- Brand Uniqueness: Vehicles differ in Reliability (affecting wear rate) and Maintainability (affecting service cost and time).
- New Workshop System:
  - Inspection: Detects hidden faults.
  - Maintenance: Restores the service level.
  - Repair: Fixes specific, identified breakdowns.
  - Overhaul: Partially restores the vehicle's overall condition.

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

### 💧 Service

This parameter reflects the state of consumables: oil, filters, technical fluids, etc.

- **What does Service affect?**
This is a critically important parameter. A low Service level significantly accelerates the decline of Condition. Timely maintenance is the best way to save money on expensive repairs in the future.

- **How does it decrease?**
It decreases with engine operating hours, simulating the natural wear of consumables.

- **How to restore it?**
It is restored to 100% through the Maintenance procedure in the workshop.

## 2. Breakdowns

The most interesting part of the mod. As the vehicle's Condition drops, the probability of random breakdowns increases.

#### Chance and Severity of Breakdowns
The lower the vehicle's Condition, the higher the chance of a new malfunction occurring. Moreover, for a heavily worn vehicle, the probability that a breakdown will appear immediately at a major or even critical stage, skipping the minor phases, increases significantly.

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

## 3. Workshop Repairs and Service

New options are available to you in the workshop menu:

#### Inspection

- **What it does:** Mechanics perform a full diagnostic. This allows you to detect hidden faults, determine the approximate Condition level, and see if Service is needed.

- **When to use:** Whenever you feel something is "wrong" with the vehicle, or when a warning light is on the dashboard.

#### Maintenance

- **What it does:** Replaces all oils, filters, and fluids. Restores the Service bar to 100%.

- **When to use:** Regularly! The cost and duration of this procedure are fixed for each vehicle, so there's no point in waiting for the service level to drop to zero.

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

#### ⏱️ Time and Planning: A New Layer of Strategy
Beyond money, all workshop procedures require time. The duration of a service or repair depends on the vehicle's Maintainability (simpler machines are fixed faster).

 **Important:** The workshop has operating hours. All work is paused overnight and resumes only when the workshop opens the next day.
 
 This adds a new layer of strategy: you now need to plan when to take your vehicles in for service. An urgent repair on a combine during the harvest season might extend into the next day, leading to downtime and financial loss.

## 4. Vehicle Characteristics: Reliability and Maintainability

Each brand of vehicle in the game now has two parameters based on its real-world reputation:

#### ✅ Reliability

- **What it is**: Shows how well-made the vehicle is. Displayed with a checkmark icon in the shop menu.

- **What it affects:** A vehicle with high reliability loses Condition more slowly.

Examples: Premium European and American brands are generally more reliable than budget or older Eastern European counterparts.

#### 🔧 Maintainability

- **What it is:** Shows how easily and cheaply the vehicle can be serviced and repaired.

- **What it affects:** A vehicle with high maintainability requires less money and time for all workshop operations and restores its Condition better after an overhaul.

Examples: Simple, older vehicles are often more maintainable than modern machines packed with electronics.
