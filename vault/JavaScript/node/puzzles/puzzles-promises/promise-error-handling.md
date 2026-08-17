# Promise Puzzles, Error Handling

> [!tldr]
> Questions about how errors propagate through await, try/catch/finally, and how rejection behaves differently from resolution.

Part of [[puzzles-promises]].

---

## 7. Await a rejection after a success

```js
async function example() {
  const data = await fetchData();
  console.log(data);
  await Promise.reject(new Error('Error occurred'));
  console.log('End');
}

example().catch(error => console.log(error.message));
```

> [!example]- Answer
> ```text
> Data
> Error occurred
> ```
> `End` never prints. An `await` on a rejected promise behaves exactly like `throw`, so it leaves the function, and the caller's `.catch` picks it up.

---

## 8. try, catch, and a return

```js
async function example() {
  try {
    const data = await failData();
    console.log(data);
  } catch (error) {
    console.log(error.message);
    return 'Error';
  } finally {
    console.log('Finally');
  }
  console.log('End');
}

example();
```

> [!example]- Answer
> ```text
> Error occurred
> Finally
> ```
> `End` never runs, because the `catch` returned. `Finally` still runs, because `finally` runs on the way out however you leave.

---

## 9. try, catch, and a throw

```js
async function example() {
  try {
    const data = await failData();
    console.log(data);
  } catch (error) {
    console.log(error.message);
    throw new Error('Another error');
  } finally {
    console.log('Finally');
  }
  console.log('End');
}

example().catch(error => console.log(error.message));
```

> [!example]- Answer
> ```text
> Error occurred
> Finally
> Another error
> ```
> The original error was swallowed and replaced. `Finally` runs before the caller sees anything. If you need both errors, pass the first as the `cause` option rather than discarding it.

---

## 10. A catch that catches nothing

```js
async function example() {
  const data = await fetchData();
  console.log(data);
  try {
    await fetchData();
  } catch (error) {
    console.log(error.message);
  }
  console.log('End');
}

example();
```

> [!example]- Answer
> ```text
> (one second)
> Data
> (another second)
> End
> ```
> Two sequential awaits, so two seconds total. The `catch` never fires because nothing rejected.

---

## 11. then and finally with no await

```js
async function example() {
  fetchData()
    .then(console.log)
    .finally(() => console.log('Finally'));
  console.log('End');
}

example();
```

> [!example]- Answer
> ```text
> End
> (one second passes)
> Data
> Finally
> ```
> The chain was started but not awaited, so the function finished first. `finally` runs after the `then`, and passes the value through untouched.

---

## 12. finally on an awaited promise

```js
async function example() {
  const data = await fetchData();
  console.log(data);
  await fetchData().finally(() => console.log('Finally'));
  console.log('End');
}

example();
```

> [!example]- Answer
> ```text
> (one second)
> Data
> (another second)
> Finally
> End
> ```
> `finally` attached to an awaited promise runs before the `await` completes, so `Finally` comes before `End` rather than after it. Compare puzzle 11, where nothing was awaited and the whole chain landed after `End`.

---

## 13. Promises nested three deep

```js
function chainedPromises() {
  return new Promise(res1 =>
    res1(new Promise(res2 =>
      res2(new Promise(res3 => setTimeout(res3, 1000, 'Data'))))));
}

async function main() {
  console.log('start');
  console.log(await chainedPromises());
}

main();
```

> [!example]- Answer
> ```text
> start
> (one second passes)
> Data
> ```
> One `await` unwraps all three. Resolving a promise with another promise makes the outer one adopt the inner one, so you never get a promise of a promise back.

---

## 14. Which line did the try block reach

The suffix numbers are the whole point of this one.

```js
async function example() {
  try {
    const data = await failData();
    console.log(data + ' 1');
  } catch (error) {
    console.log(error.message + ' 2');
  }
  console.log('End');
}

example();
```

> [!example]- Answer
> ```text
> Error occurred 2
> End
> ```
> The `1` never appears, which is the proof that the `try` block was abandoned at the `await` and the line after it never ran. Marking your log lines like this is a cheap way to find out how far execution actually got.

---

## 15. Awaiting something already resolved

```js
async function example() {
  const data = await fetchData();
  console.log(data);
  await Promise.resolve('Resolved');
  console.log('End');
}

example();
```

> [!example]- Answer
> ```text
> Data
> End
> ```
> Compare puzzle 7, which is this exact shape with `Promise.reject` instead, where `End` never prints. The pair is worth keeping together: the only difference is whether the second promise resolved, and that decides whether the rest of the function exists.
>
> Worth knowing that `await Promise.resolve(x)` still yields to the microtask queue rather than continuing straight through. `End` runs in a later microtask, not on the same line of execution.
