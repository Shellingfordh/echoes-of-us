# Development Guide (示例)

启动：打开 project.godot，运行 main scene（scenes/main/main.tscn）

分支策略：feature/*，PR 到 main，经负责人审查后合并

代码规范：GDScript 使用 snake_case，函数注释简短说明输入输出；重要逻辑留 assert 测试片段

调试工具：在 LevelManager 打开 debug log（记录 tension、连接数、事件触发）

提交示例："Add basic TieLine system" — 描述做了什么、如何测试、注意事项

<!-- ponytail: 最小开发指南，环境与 CI 细节按需补充 -->
