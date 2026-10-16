# TRP spec excerpt: Recoil + hip wander (Apache-2.0, github.com/JuanFNQ/TRP TRP/docs/spec/weapon-handling.md, fetched 2026-10-15)


**Clock:** the springs and effectors run at a fixed 60 steps a second (one step = 1/60 s), never per rendered frame; the camera blends run per frame.
## Springs

`Spring` (hands position, hands rotation, camera rotation, camera position). Three components. State: `Current`, `Velocity`. Per fixed step, with no time step in the formula:

```
if forces were added since the last step:
    Velocity += (clamp(Force, ±AccelerationMax per component) + ForceLimitless) * InputIntensity
    clear the forces
Velocity -= (Current - Zero) * ReturnSpeed
Velocity *= Damping
Current  += Velocity
```

The value read is `Zero + Current`. Since `Current` itself is drawn to `Zero`, an offset held in `Zero` counts twice once the spring has settled: a full lean puts 5 in `Zero` and the weapon and the camera end up rolled 10 degrees. A recorded trace confirms both: `Current` settles at 5 and the camera's roll at 10.

| Spring | ReturnSpeed | Damping | AccelerationMax |
|---|---|---|---|
| HandsPosition | 0.1 | 0.5 | 10 |
| HandsRotation | 0.066 | 0.66 | 10 |
| CameraRotation | 0.05 | 0.5 | 100 |
| CameraPosition | 0.25 | 0.66 | 10 |

`InputIntensity` of both hands springs is set to `IntensityByAiming²` when aiming or stance changes. `IntensityByAiming` is 1 from the hip and `Aiming.AimProceduralIntensity` (0.75) while aiming. The same change sets the recoil rotation's `Intensity` to `IntensityByAiming` and rescales the sway factors.

`BetterSpring` (sway). A damped harmonic oscillator integrated exactly over the step, with position and velocity as state. The prefab says `angularFrequency` 7 and `dampingRatio` 0.8, but the game replaces both from the settings object whenever the character's condition is refreshed: `lerp(SWAY_FREQ_NORMAL_DAMAGED)` and `lerp(SWAY_DAMPING_NORMAL_DAMAGED)` over arm damage plus overweight. For a sound, unburdened character that is 8 and 0.8, and with 8 the simulation's sway in a recorded turn is within 0.13 degrees of the game's (with 7 it was 30% too large). The underdamped case:

```
ωζ = ω * ζ,  α = ω * sqrt(1 - ζ²),  x = pos - equilibrium
e = exp(-ωζ * dt),  c = cos(α dt),  s = sin(α dt),  b = (vel + ωζ x) / α
pos = equilibrium + e * (x c + b s)
vel = -e * ((x ωζ - b α) c + (x α + b ωζ) s)
```

Effectors add to its velocity directly.


## Recoil

`ShotEffector` holds two recoil models; the prefab selects the newer one (`RecoilPipeline` 1, `NewRecoilShotEffect`). It has three springs, called processes: the weapon's rotation, the weapon's position and the camera's rotation. A fourth layer, the weapon's own curves, is described at the end.

### What a shot does

The firearm code calls `Shoot(strength)` once per shot with `strength = 1 + ammoRec / 100` from the cartridge (the stock 7.62x39 PS has 0, so 1). `Shoot`:

1. Sets the camera's aiming rate (`CameraSmoothBlender`) to `CameraSnap * Aiming.CameraSnapGlobalMult` and holds it there for 0.2 s; after that it climbs back to `CameraSmoothSteady` (8) at 5 per second. `CameraSnap` is the weapon's (AKM 3.5; the prefab's 3 is used when the weapon gives none) and the multiplier is 2, so the rate drops from 8 to 7 for the AKM.
2. Adds the recoil force, below.
3. Tells the breathing effector. **Unread.**

Adding the force:

```
shot += 1                                  (the count within one run of automatic fire)
if shot == RecoilStableIndexShot: the rotation process enters stable mode
multiplier = clamp(shot, 1, stable) / stable   if shot >= ProgressPowerShot (2), else 1

rotationPower = random(rotation range + group sums) * strength
positionPower = random(position range + group sums) * strength
angle range   = base range + group sums; in stable mode widened by ±angleAdd,
                where angleAdd grows by RecoilStableAngleIncreaseStep per shot,
                clamped to ProgressRecoilAngleOnStable
a = random(angle range)

direction = ( -sin(a) * rotationPower * Ix,
               cos(a) * rotationPower * Iy,
               positionPower * Iz ) * HandPositionRecoil.Intensity
```

The three random draws come in that order. `I` is the stance factor: `Aiming.RecoilXIntensityByPose`, `RecoilYIntensityByPose` and `min(template.RecoilPosZMult, RecoilZIntensityByPose)`, each indexed by stance: 0 prone, 1 crouched, 2 standing. "Crouched" here means the stance level is below 0.11; anything higher counts as standing. Values: x (0.6, 0.7, 1), y and z (0.7, 0.7, 1).

The ranges are set when the weapon is taken in hand:

```
parts = max(0, (1 + sum of the fitted parts' Recoil / 100) * (1 - skill terms))
rotation range = BasicRecoilRotationStrengthRange (0.9, 1.15)
                 * (RecoilForceUp * parts + Aiming.RecoilVertBonus) * 0.1399
position range = BasicRecoilPositionStrengthRange (0.65, 1.05)
                 * (RecoilForceBack * parts + Aiming.RecoilBackBonus) * 0.1399
base angle range = RecoilAngle ± RecolDispersion, in degrees
```

Both bonuses are 20. Each entry of the weapon's `ShotsGroupSettings` covers a range of shot numbers and adds to the two strength ranges and to the two ends of the angle range (in degrees, despite the field's name). The AKM has one group, for shots 1 to 200, that narrows its 74..96 degree range to 80..90. An angle of 90 is straight up.

The direction is then routed by the prefab's `ShotRecoilProcessValues`, each "this axis of the direction, times a factor, into that axis of that process":

| From | Into | Factor |
|---|---|---|
| x | weapon rotation x | 0.15 |
| y | weapon rotation z | 0.15 |
| z | weapon position y | 0.0007 |
| x | camera rotation x | the weapon's `RecoilCamera` |
| y | camera rotation y | minus `RecoilCamera` |

Two more entries on the prefab name targets the code does not handle. So a shot raises the muzzle (negative x), turns it a little sideways (z), pushes the weapon back along the barrel (+y) and kicks the camera.

### The position and camera processes

Per physics step, with no time step in the formula:

```
if a force was added: Velocity += Force * Intensity; clear it
Velocity -= (Current - Offset) * ReturnSpeed
Velocity *= Damping
Current  += Velocity
```

Weapon position: return 0.08, damping 0.5, intensity 1. Camera rotation: 0.05, 0.5, 1. `Offset` is where other effects (breathing) move the rest point; it is zero until those are in.

### The rotation process

`NewRotationRecoilProcess`. Its `ReturnSpeed` is the weapon's `RecoilReturnSpeedHandRotation * Aiming.RecoilConvergenceMult` (AKM 2.4), its `Damping` the weapon's `RecoilDampingHandRotation` (0.86), and its `Intensity` is `IntensityByAiming`. A force pushed into it is first multiplied by the weapon's `RecoilCategoryMultiplierHandRotation` (0.19) and by the shot multiplier above. In stable mode a push also zeroes the velocity first.

Per physics step:

```
if a force was added:
    Velocity += Force * Intensity; clear it
    curveTime = min(|Current|², curveTime)
    if stable:
        next = stableCurrent + Velocity * random(NextStablePointDistanceRange (0.1, 8))
        if |next - Current| > 0.95: next = Current + (next - Current) * 0.95
if not automatic fire: speed = ReturnSpeed * ReturnSpeedCurve(curveTime)
if a force was added, automatic fire, not stable: speed *= shot multiplier
curveTime += dt
Velocity *= Damping
if stable:  Current += (next - Current) * ToNextCurrentSpeed (0.2)
else:       Velocity -= Current * speed;  Current += Velocity
return path (below)
if not automatic fire and peakX != 0:
    remaining = |clamp(Current.x, peakX, -0.01) / peakX|
    k = clamp(1 - remaining, 0.01, 1) * 0.01
    Current.x and Current.z move toward the settle point by the fraction k
```

`ReturnSpeedCurve` is flat at 0.008 on the prefab, so a single shot's return rate is `2.4 * 0.008` per step for the AKM. The clamp has its bounds the wrong way round until the first shot (`peakX` starts at 0.01); the engine's clamp then returns the lower bound, and that behaviour is kept.

Stable mode starts on the weapon's `RecoilStableIndexShot`-th shot of a run (5 for the AKM) and remembers where the muzzle was. From then on the muzzle no longer climbs: each shot picks a point a random distance along the kick from the remembered point and the muzzle moves a fifth of the way there per step. Leaving automatic fire ends stable mode, resets the shot count and the angle widening.

The return path, each step:

- While the muzzle is still rising (`Current.x` below its last value) after a push: pick the settle point, x from the weapon's `PostRecoilVerticalRangeHandRotation`, sideways from `PostRecoilHorizontalRangeHandRotation` on the side the muzzle is already on; remember `peakX = Current.x`; set the sideways impulse to `|Current.x * ReturnSpeed| * RecoilReturnPathOffsetHandRotation`; and pick the side from the sign of `Current.z` (at random if it is zero).
- Otherwise, outside automatic fire: the impulse is multiplied by `RecoilReturnPathDampingHandRotation` each step and added to the sideways velocity on the chosen side until it falls below 0.001. Then the return path ends, or the whole process resets if the weapon says `ResetAfterShot`.

So the muzzle does not come back along the line it went up, and it settles near, not at, where it started.

### Onto the weapon

- Position: the position process's value is added to `Weapon_root_anim`'s local position.
- Rotation: after the sway rotation about `RotationCenter`, the weapon is turned by the rotation process's value about `RecoilPivot` (the weapon's `RecoilCenter`; AKM (0, -0.25, 0)). The game builds this turn from the three angles rotated into world axes; the simulation applies the same angles in the bone's own axes, which differs only in the second order of a few degrees.
- When the field-of-view scale is below 1, the x and z angles are first replaced by `atan(tan(angle) * scale)`.

### Onto the camera

Each rendered frame, after the camera's rotation is built, `AddHandRecoilRotateToCamera` blends it. `c` is the rotation process's current angles and `speed` a blend fraction kept between the weapon's `CameraToWeaponAngleSpeedRange` (AKM 0.1 to 0.2) and moved by `CameraToWeaponAngleStep * frameTime` (0.1):

- Not aiming: the camera's rotation is blended from its last blended value toward the freshly built one by the top of the range. This only smooths it.
- Aiming, not in automatic fire: target = the built rotation with its y component zeroed, times `Euler(c)`; `speed` falls; blend toward the target by `speed`. The view rises with the muzzle.
- Aiming in automatic fire before stable mode: the same with `speed` rising. If `c` is exactly zero the camera is left alone.
- Aiming in stable automatic fire: the last target is kept, with only its z component taken from the built rotation.

Then the camera process's angles are added to the camera's Euler angles. The blends are fractions per frame, so this too depends on the frame rate.

### The weapon's own curves

`WeaponRecoilSettings` in the item template, when enabled, lists curves that each drive one axis of the weapon rotation, weapon position or camera rotation. Each has a clock that a shot resets to zero and that advances by `dt * CurveTimeMultiply` per physics step; its value is `curve(clock) * CurveValueMultiply`, or `* CurveAimingValueMultiply` while aiming. The values are added to the matching process's output. The AKM has three, all the same shape (0 at 0, 2 at 0.1, -0.75 at 0.3, 0 at 1): a roll of the weapon about its barrel, a small push back, and a roll of the camera.

The game starts the clocks at zero, so the curves play once as the weapon is taken in hand. The simulation starts them finished.

### Measured (stock AKM, standing, untrained)

One shot from the hip raises the muzzle 1.6 degrees and brings the weapon back 26 mm; aiming, 1.2 degrees. Held automatic fire runs at 600 a minute; the muzzle is 1.5 degrees up when the second shot fires and about 7 to 8 degrees from the fifth on, never above 10.3.


- **The muzzle's wander from the hip.** Two more wandering values, amplitude 1 each, delay 0.2 to 0.7 s, give a target `(x, 0, z) * Intensity * HipPenalty` when not aiming and zero when aiming. The recoil rotation's `Offset` moves a tenth of the way to it per step, and lands on it once close. Because the recoil rotation is read as `Offset + Current`, the muzzle drifts about a degree either way when the weapon is not at the shoulder.
- **A shot from the hip** adds to a gain: `gain += max(0, perShot - 0.2 * (sqrt(gain) - 1))`. The gain holds for a delay and then falls to 0 at a rate; the weapon gives all three (`HipInnaccuracyGain` 0.16, `HipAccuracyRestorationDelay` 0.2 s, `HipAccuracyRestorationSpeed` 7 for the AKM). The wander's amplitude becomes `1 + sqrt(gain)`, at most 3, and its hardness jumps to 0.15 and eases back to 0.1. The shot also throws the offset at once to a new point drawn from the two wandering values.

- **Recoil, shot by shot** (2026-10-09; the user asked for the recoil to be gone over "for peace of mind"). The first comparison above had one shot and one burst. The recordings now hold 179 shots between them (the third to the tenth: single shots from the hip, aimed and lying, and a one-second burst from the hip and aimed in each), and the replay takes a seed (`replay --seed`), so the game's shots are set against the simulation's spread: forty seeds on the tenth recording's frames and conditions, 1,040 shots. The game's random draws are its own, so it is sizes and ranges that compare, not one shot with another.
  - *Each shot's own force, worked back from the springs.* The position spring and the camera spring step as `V = (V + F - C * r) * d; C += V`, so the force a step took is `(C1 - C0) / d - (C0 - Cm1) + r * C0` from three recorded values (`local\kicks.sh`). Standing, 169 shots in the game: the kick back is 18.48 to 29.72 mm, mean 23.7 (the simulation: 18.49 to 29.78, mean 24.1); the kick to the camera 0.795 to 1.014 degrees, mean 0.900 (0.795 to 1.014, mean 0.906); the kick's direction before steady fire 80.1 to 89.9 degrees from level, mean 84.9 (80.0 to 90.0, mean 85.4), and from the fifth shot of a burst, where its range widens, 70.3 to 90, mean 82.7 (66.3 to 90, mean 81.8). Lying, 10 shots: back 15.3 to 20.8 mm (12.9 to 20.8: the top is the standing top times the lying factor of 0.7 on both sides; the game's ten happen not to reach the bottom, a one in thirty chance), camera 0.481 to 0.603 degrees (0.478 to 0.609). One recorded shot fell on a frame with two physics steps, which this working-back misreads; it is left out.
  - *A single shot, as the springs answer it* (`local\shots.sh`: the largest value after each shot). From the hip, 14 in the game: the muzzle climbs 1.82 degrees on average, 1.62 to 1.99 (the simulation 1.77, 1.56 to 1.99), reaching it 0.143 s after the rounds drop (0.141); the weapon comes back 18.0 mm, 15.5 to 21.7 (19.8, 15.3 to 24.5); the camera kicks 0.81 degrees (0.79); half a second on the muzzle is 0.15 degrees past rest on its way back (0.15). Aimed, 14: 1.33 degrees, 1.17 to 1.48 (1.34, 1.17 to 1.51), 18.6 mm (19.8), camera 0.80 (0.80). Lying and aimed, 8: 0.80 degrees (0.80), 15.4 mm (13.9), camera 0.48 (0.48). Every recorded figure lies inside the simulation's own least and most, or within half a percent of them.
  - *Automatic fire, the muzzle's height as each shot fires* (7 bursts each way in the game, 40 in the simulation; degrees). From the hip, shots 2 to 5: 1.65, 2.57, 3.66, 5.19 in the game and 1.67, 2.62, 3.73, 5.27 here; held from the seventh at 7.3 on average, between 6.0 and 8.8 (7.1, between 5.3 and 9.5). Aimed: 1.20, 1.92, 2.74, 3.86 and 1.16, 1.92, 2.74, 3.85; held at 5.6, between 4.9 and 7.1 (5.3, between 4.0 and 7.1). The game's first four are 1.5 to 2% under the simulation's from the hip and level with them aimed; with seven bursts that is inside the spread.
  - *What was wrong: when a single shot's kick reaches the springs.* Found by the time to the muzzle's peak, which was 0.143 s in the game and 0.133 here. The game does not kick the weapon when the shot is made: the shot raises a flag, and the firearm controller's late update, after the frame's physics steps have gone through the springs, gives the recoil its kick; and a single shot takes its round a frame before it makes the shot (`firing.md`, "The recoil's kick, and which physics step takes it"). With that built, the frames from the rounds dropping to the springs first moving are the game's for all 16 recorded first single shots (they were the game's for 8), and the time to the peak is 0.141 s.
