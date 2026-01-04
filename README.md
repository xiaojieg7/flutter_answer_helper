this is  answer_helper app
It supports one-click import of the question bank. You can use AI to generate the JSON question bank and then import it.

### 使用ai生成题库
1. 生成题库需要用户手动去使用ai生成，提供相应的题目图片或者各种文档，
让ai根据下面的json标准生成即可导入到软件中 
例如 腾讯元宝/通义千问/豆包/deepseek 提供的题目图片或文档，让ai根据json标准生成即可。
2. 生成题库 必须符合json的标准格式 生成后使用.json文件 即可导入到软件中。
### 导入题库
1. 点击应用首页的“导入题库”按钮。
2. 在文件选择器中选择符合格式的JSON文件。
3. 确认导入，应用将解析文件并将题库添加到本地数据库。
### 题库json格式 // 1.0
{
  "schema_version": "1.0",
  "metadata": {
    "title": "Linux设备驱动开发题库示例",
    "subject": "Linux设备驱动",
    "difficulty": "中级",
    "total_questions": 5,
    "created_date": "2024-01-01",
    "score_mode": "single" //单题计分 single,平均计分total_questions/100 average
  },
  "questions": [
    {
      "id": 1,
      "type": "single",
      "question": "Linux中有()类驱动。",
      "options": {
        "A": "字符设备驱动",
        "B": "通信设备驱动",
        "C": "网络设备驱动",
        "D": "块设备驱动"
      },
      "correct_answer": "A",
      "explanation": "Linux标准设备驱动分为字符设备、块设备和网络设备三类。",
      "score": 2
    },
    {
      "id": 2,
      "type": "multiple",
      "question": "MMU主要完成的功能包括()。",
      "options": {
        "A": "完成虚拟空间到物理空间的映射",
        "B": "内存保护",
        "C": "设置存储器的访问权限",
        "D": "设置虚拟存储空间的缓冲特性"
      },
      "correct_answer": ["A", "B", "C", "D"],
      "explanation": "MMU负责地址映射、内存保护、访问权限设置和缓存管理。",
      "score": 3
    },
    {
      "id": 3,
      "type": "true_false",
      "question": "Linux内核可以直接对物理地址进行读写操作。",
      "correct_answer": false,
      "explanation": "Linux通过虚拟地址操作寄存器，无法直接读写物理地址，需经MMU映射。",
      "score": 1
    },
    {
      "id": 4,
      "type": "fill_in_blank",
      "question": "节点是由一堆([填空1])的组成,节点都是具体的设备",
      "options": {},
      "correct_answer": "属性",
      "explanation": "节点由属性组成，每个属性是键值对，描述设备的特征。",
      "score": 2
    },
    {
      "id": 5,
      "type": "short_answer",
      "question": "简述字符设备驱动开发的基本流程。",
      "correct_answer": "字符设备驱动开发基本流程包括：1. 申请设备号；2. 注册字符设备；3. 实现file_operations操作集；4. 自动创建设备节点；5. 编写具体的读写控制函数。",
      "explanation": "字符设备驱动需要遵循Linux驱动框架，从设备号申请到操作函数实现都需要按规范进行。",
      "score": 10
    }
  ]
}

