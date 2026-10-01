# POC 3 benchmark review

Human visual acceptance (AC-43) remains open. The canonical final set contains 18 production-simulation captures in [final-benchmark](final-benchmark/); matching earlier views are preserved in [baseline](baseline/).

Start with these close views:

- [Settlement](final-benchmark/room_a-settlement-close.png)
- [Citizen](final-benchmark/room_a-citizen-close.png)
- [Resource carrying](final-benchmark/room_a-resource-carry-close.png)
- [Builder](final-benchmark/room_a-builder-close.png)
- [Completed grapple](final-benchmark/room_a-grapple-complete.png)
- [Climbing citizen](final-benchmark/room_a-citizen-climb-close.png)
- [Elevated citizen](final-benchmark/room_a-elevated-citizen-close.png)

Every image has a neighboring `.txt` camera/state sidecar. Wide views preserve scale context but do not establish character detail quality.

The [final Room A scenario](logs/final-benchmark-room-a.log), [Room B](logs/final-room-b.log), and [accepted photo room](logs/final-photo-room.log) passed the actual delivery/build/deploy/climb/explore/reuse loop.

Isolated Godot 4.7.2 Compatibility benchmark, VSync disabled, 50 citizens, eight seconds per view on RTX 5090:

| View | FPS | Median ms | p95 ms | Draw calls |
| --- | ---: | ---: | ---: | ---: |
| Room | 695.2 | 1.431 | 1.478 | 770 |
| Settlement | 782.2 | 1.271 | 1.320 | 825 |
| Citizen | 720.9 | 1.417 | 1.496 | 677 |

[Raw measurements](performance.json). These measurements do not establish performance on lower-end hardware. The [acceptance record](acceptance.md) describes remaining visual limitations and preserved failed iterations.
