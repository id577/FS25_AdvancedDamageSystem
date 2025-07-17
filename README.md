# FS25_AdvancedDamageSystem
Advanced Damage System mod for Farming Simulator 25.
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

#  Philosophy Behind the Mod
The main goal of this mod is to transform vehicle maintenance from a simple chore into a deep and engaging layer of gameplay. Instead of just clicking a "Repair" button, you will have to make meaningful decisions that directly impact your farm's success.
- **Strategy Over Spam.** You now need to plan your maintenance. Servicing your vehicles too often will drain your bank account, but waiting too long will lead to breakdowns at the worst possible moment. You must find the right balance.
- **Real Consequences & Risk.** The way you treat your equipment directly impacts its lifespan and reliability. An old, worn-out tractor truly feels different from a new one—it might just die in the middle of a field during harvest. Will you push your old machinery to its limits, risking it all? Or will you invest in new, dependable equipment?
- **Meaningful Brand Choices.** Brands now have a distinct identity. What will you choose: a premium, reliable machine that is expensive and time-consuming to service? Or a cheap "workhorse" that suffers from frequent minor issues but can be fixed quickly and inexpensively?
With this mod, vehicle ownership becomes a true management challenge for your fleet.

# Key Features
Complete Overhaul of the Damage and Wear System
The mod completely replaces the standard damage system in FS25 with a deeper, more realistic model based on two key parameters:
- **Condition:** Represents the overall mechanical wear and tear of the vehicle's components. It decreases from high loads, overheating, and improper service. Low condition significantly increases the chance of critical breakdowns. It can only be restored through an Overhaul.
- **Service:** Indicates the state of consumables (oils, filters, etc.). It decreases with operating hours. Poor service accelerates the wear of the vehicle's Condition. It is restored through Maintenance.

# Dynamic Breakdown System
Vehicles can break down at the most inconvenient times. The chance of a breakdown is directly dependent on its Condition.
- Each breakdown has several stages, from minor glitches to a complete component failure.
- Breakdowns can progress over time if not addressed.
- Dozens of unique malfunctions for different systems:
  - **Engine:** ECU malfunction, turbocharger wear, fuel pump or injector failure, clogged carburetor (for older equipment).
  - **Transmission:** Clutch slip, synchronizer wear, PowerShift hydraulics failure.
  - **Brake System:** Reduced brake effectiveness, leading to complete failure.
  - **Hydraulics:** Slower operation of attached implements.
  - **Electrical System:** Flickering or total failure of lights, starting issues.
  - **Cooling System:** Thermostat malfunction.
      
# Advanced Temperature Simulation
The mod introduces a detailed thermal model for the engine and transmission (for modern tractors with CVT).
- The temperature of each component is calculated separately and depends on load, RPM, speed, ambient temperature, and even the vehicle's dirt level.
- **Overheating has consequences**: from power reduction to critical engine failure on older equipment.
- Modern vehicles are equipped with an overheat protection system that automatically reduces power to prevent damage.

# New Workshop Maintenance System
Simple repairs are replaced with a multi-level maintenance system that requires planning and investment.
- **Inspection:** Allows for the detection of hidden faults that have not yet manifested.
- **Maintenance:** Restores the Service level to 100%, replacing "virtual" oils and filters.
- **Repair:** Fixes specific, identified breakdowns.
- **Overhaul:** A costly and time-consuming procedure that partially restores the vehicle's Condition.

All operations require time (in-game) and money, with the cost depending on the vehicle's price, age, and maintainability.

# Realistic Effects from Malfunctions
Each breakdown has a tangible impact on the vehicle's behavior:
- Reduction in engine power and torque.
- Increased fuel consumption.
- Power loss and unstable engine performance.
- Problems with gear shifting or gears popping out.
- Reduced braking effectiveness.
- Failure of lights and hydraulics.
- Engine starting problems, especially when cold.

Demonstration of some effects: https://www.youtube.com/watch?v=NpnlvY25Xl0&list=PL73V6HaxZ69gRgpLGkHpb_k5Qh1w4ZtHa

# Unique Characteristics for Brands and Vehicle Age
- **Reliability and Maintainability:** Different vehicle brands have their own reliability ratings (affecting speed of wear) and maintainability ratings (affecting service cost and speed).
- **Year of Manufacture:** The vehicle's age affects its behavior. For example, older tractors lack advanced overheat protection, making them more vulnerable.

# Improved UI and HUD
The mod adds new interface elements to track the state of your vehicles, including detailed information in the workshop menu and new indicators on the dashboard.

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
