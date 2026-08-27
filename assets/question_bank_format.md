# 答题助手题库格式规范 2.0

> 版本：2.0
> 更新日期：2026-08-27
> 说明：题库以 JSON 文件形式导入/导出。相比 1.0 版本，新增题目配图字段 `image_base64`（base64 编码直接内嵌于 JSON，无需依赖本地图片路径）。

## 一、整体结构

```text
{
  "schema_version": "2.0",     // 格式版本号
  "metadata": { ... },         // 题库元信息
  "questions": [ ... ]         // 题目列表
}
```

## 二、完整 JSON 示例

```json
{
  "schema_version": "2.0",
  "metadata": {
    "title": "2026 年 Java 基础模拟题",
    "subject": "计算机科学",
    "difficulty": "中等",
    "total_questions": 5,
    "created_date": "2026-08-27",
    "score_mode": "average"
  },
  "questions": [
    {
      "id": 1,
      "type": "single",
      "question": "下列哪个不是 Java 的基本数据类型？",
      "options": {
        "A": "int",
        "B": "double",
        "C": "String",
        "D": "boolean"
      },
      "correct_answer": "C",
      "explanation": "String 是引用类型，不是基本数据类型。",
      "score": 2
    },
    {
      "id": 2,
      "type": "multiple",
      "question": "以下属于面向对象三大特性的是哪些？（多选）",
      "options": {
        "A": "封装",
        "B": "继承",
        "C": "多态",
        "D": "重载"
      },
      "correct_answer": ["A", "B", "C"],
      "explanation": "封装、继承、多态是面向对象三大特性；重载只是语法特性。",
      "score": 3,
      "image_base64": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUg..."
    },
    {
      "id": 3,
      "type": "true_false",
      "question": "Java 中接口可以包含构造方法。",
      "correct_answer": "错误",
      "explanation": "接口不能被实例化，因此不包含构造方法。",
      "score": 1
    },
    {
      "id": 4,
      "type": "fill_in_blank",
      "question": "Java 中所有类的根父类是____。",
      "correct_answer": "Object",
      "explanation": "java.lang.Object 是所有类的公共父类。",
      "score": 2
    },
    {
      "id": 5,
      "type": "short_answer",
      "question": "简述 == 与 equals() 的区别。",
      "correct_answer": "== 比较引用地址；equals() 比较对象内容（可被重写）。",
      "explanation": "基本类型用 == 比较值；引用类型 == 比较地址，equals 默认同 == 但常被重写。",
      "score": 5,
      "image_base64": null
    }
  ]
}
```

## 三、顶层字段说明

| 字段 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| schema_version | String | 是 | 格式版本号，固定为 `"2.0"` |
| metadata | Object | 是 | 题库元信息，见第四节 |
| questions | Array | 是 | 题目数组，每个元素为一道题，见第五节 |

## 四、metadata 字段说明

| 字段 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| title | String | 是 | 题库名称，显示在科目详情页的题库卡片上 |
| subject | String | 是 | 所属科目名称 |
| difficulty | String | 是 | 难度描述，如“简单”“中等”“困难” |
| total_questions | Number | 是 | 题目总数，建议与 questions 数组长度一致 |
| created_date | String | 是 | 创建日期，建议格式 `yyyy-MM-dd` |
| score_mode | String | 否 | 计分模式，默认 `"average"`（平均分）；可自定义 |

## 五、questions 题目字段说明

| 字段 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| id | Number/String | 是 | 题目原始编号，同题库内不可重复 |
| type | String | 是 | 题型标识，见第六节题型对照表 |
| question | String | 是 | 题干文本 |
| options | Object | 否 | 选项键值对，如 `{"A": "...", "B": "..."}`；单选/多选必填，其他题型可省略 |
| correct_answer | Any | 是 | 正确答案，类型随题型变化，见第六节 |
| explanation | String | 是 | 答案解析 |
| score | Number | 否 | 单题分值，默认 `1` |
| image_base64 | String/null | 否 | **2.0 新增**。题目配图（单张），以 base64 编码内嵌；无图时可省略或传 `null` |

### image_base64 补充说明

- 编码格式：完整的 Data URI（如 `data:image/png;base64,xxx`）或纯 base64 字符串均可。
- 支持格式：PNG / JPEG / GIF / WebP。
- 应用行为：答题页、背题模式在题干下方自动渲染配图；点击图片进入全局查看器，支持双指缩放（0.5~5 倍）与拖动查看。
- 导出：编辑页上传图片后自动转为 base64 存入数据库，导出时写入该字段。

## 六、题型与 correct_answer 对照表

| type 取值 | 题型 | correct_answer 类型 | 示例 |
| --- | --- | --- | --- |
| `single` | 单选题 | String（选项键，如 `"A"`） | `"C"` |
| `multiple` | 多选题 | Array\<String\>（选项键列表） | `["A", "B", "C"]` |
| `true_false` | 判断题 | String（`"正确"` / `"错误"`） | `"错误"` |
| `fill_in_blank` | 填空题 | String | `"Object"` |
| `short_answer` | 简答题 | String | `"== 比较引用地址…"` |

## 七、兼容性说明

- **1.0 → 2.0 差异**：仅新增可选字段 `image_base64`，其余结构不变。
- 导入 1.0 旧题库时，应用自动将图片字段置空，不影响其余数据解析。
- 编辑器中补充的图片统一以 base64 入库并标记为 2.0 格式导出。
