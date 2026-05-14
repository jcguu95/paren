# C 裡的 Testing 和 Namespace

## Testing in C

C 沒有內建的 test framework。實務上有幾個層次：

### 層次一：最簡單，`assert.h`

```c
#include <assert.h>
int main() {
    assert(int_max(3, 5) == 5);
    assert(int_min(3, 5) == 3);
    assert(int_clamp(10, 0, 8) == 8);
    return 0;  // 通過了
}
// 失敗時：Assertion failed: ..., file foo.c, line 3
```

缺點：失敗就直接 abort，不會繼續跑後面的測試。

### 層次二：自己寫簡單的 test runner（C 程式員常見做法）

```c
static int tests_run    = 0;
static int tests_failed = 0;

#define CHECK(expr)                                          \
    do {                                                     \
        tests_run++;                                         \
        if (!(expr)) {                                       \
            fprintf(stderr, "FAIL: %s  (line %d)\n",        \
                    #expr, __LINE__);                        \
            tests_failed++;                                  \
        }                                                    \
    } while (0)

int main() {
    CHECK(int_max(3, 5) == 5);
    CHECK(int_min(3, 5) == 3);
    CHECK(int_clamp(10, 0, 8) == 8);

    fprintf(stderr, "%d/%d passed\n", tests_run - tests_failed, tests_run);
    return tests_failed ? 1 : 0;
}
```

### 層次三：用 PAREN/C 生成 test boilerplate（未來 showcase）

這本身也是一個很好的 showcase：用 PAREN/C 寫一個 `def-test-suite` macro，
自動幫你生成 test runner 的樣板。

---

## Namespaces in C

C 沒有 namespace。實務上有三種模擬方式：

### 方式一：前綴命名（最普遍）

```c
// 所有函數和型別都加 library 前綴
typedef struct mylib_list_node mylib_list_node;
mylib_list_node *mylib_list_push(mylib_list_node *head, int value);
void             mylib_list_free(mylib_list_node *head);
```

Linux kernel、SQLite、SDL 都這樣做。PAREN/C 生成的程式碼自然就是這種風格
（e.g. `int_push`, `float_push`, `serialize_entity`）。

### 方式二：function pointer struct（模擬 method / module）

```c
// 把相關函數集中到一個 struct 裡
typedef struct {
    int  (*max)(int, int);
    int  (*min)(int, int);
    int  (*clamp)(int, int, int);
} int_ops_t;

static const int_ops_t INT_OPS = {
    .max   = int_max,
    .min   = int_min,
    .clamp = int_clamp,
};

// 呼叫：INT_OPS.max(3, 5)
```

Linux kernel 的 `struct file_operations`、`struct vm_operations_struct` 就是這個模式。

### 方式三：`static`（file-level privacy）

```c
// 只在這個 .c 檔案裡可見，不 export 出去
static int helper_function(int x) { ... }
```

---

## 對 PAREN/C 的意義

這兩個問題其實都指向同一個 showcase 機會：

**用 PAREN/C 寫一個 `def-module` macro**，輸入是模組名稱 + 函數列表，
自動生成：
1. 帶前綴的函數定義（namespace）
2. 一個 function pointer struct（module interface）
3. 一個靜態初始化的 struct instance
4. 對應的 test 函數

這本身就是一個很強的 showcase。
