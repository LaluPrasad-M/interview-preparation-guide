# Promise Puzzles

> [!tldr]
> The combinator and error handling questions, answers folded. The rules are in [[promises]], the event loop ordering ones are in [[puzzles-scheduling]].

Assume these two helpers throughout:

```js
function fetchData(t = 1000, value = 'Data') {
  return new Promise(resolve => setTimeout(resolve, t, value));
}

function failData(t = 1000) {
  return new Promise((_, reject) => setTimeout(reject, t, new Error('Error occurred')));
}
```

---

## 1. Promise.all with a plain value

```js
const promise1 = Promise.resolve(3);
const promise2 = 42;
const promise3 = new Promise(resolve => setTimeout(resolve, 1000, 'foo'));

Promise.all([promise1, promise2, promise3]).then(values => console.log(values));
```

> [!example]- Answer
> ```text
> (one second passes)
> [3, 42, 'foo']
> ```
> Anything in the array that is not a promise is treated as already resolved. The whole thing still waits for the slowest real promise.

---

## 2. Two promises, both resolve

```js
async function example() {
  console.log('Start');
  const [data1, data2] = await Promise.all([fetchData(), fetchData()]);
  console.log(data1, data2);
  console.log('End');
}

example();
```

> [!example]- Answer
> ```text
> Start
> (one second passes, not two)
> Data Data
> End
> ```
> They run at the same time, so the total wait is the slowest one rather than the sum. Awaiting them on separate lines would take two seconds.

---

## 3. Promise.all where both reject at different times

```js
async function example() {
  console.log('Start');
  try {
    await Promise.all([failData(1000), failData(5000)]);
    console.log('Success');
  } catch (error) {
    console.log(error.message);
  }
  console.log('End');
}

example();
```

> [!example]- Answer
> ```text
> Start
> (one second passes)
> Error occurred
> End
> ```
> `Promise.all` rejects on the first failure and does not wait for the second. Four seconds of work carries on in the background regardless, it just has nowhere to report to.

---

## 4. One resolves, one rejects earlier

```js
try {
  const [data, anotherData] = await Promise.all([fetchData(1000), failData(500)]);
  console.log(data, anotherData);
} catch (error) {
  console.log(error.message);
}
```

> [!example]- Answer
> ```text
> (half a second passes)
> Error occurred
> ```
> The destructuring never happens. A single rejection means the whole `all` rejects, so no partial results reach you.

---

## 5. The same thing with allSettled

```js
const results = await Promise.allSettled([fetchData(1000, 'Resolved Data'), failData(500)]);
console.log(results);

results.forEach((result, index) => {
  if (result.status === 'fulfilled') console.log(index, 'Data:', result.value);
  else console.log(index, 'Error:', result.reason.message);
});
```

> [!example]- Answer
> ```text
> (one second passes, it waits for all of them)
> [
>   { status: 'fulfilled', value: 'Resolved Data' },
>   { status: 'rejected', reason: Error: Error occurred }
> ]
> 0 Data: Resolved Data
> 1 Error: Error occurred
> ```
> Note the shape difference: a fulfilled entry has `value`, a rejected one has `reason`. And `allSettled` never rejects, so a `try` and `catch` around it is dead code.

---

## 6. race

```js
async function example() {
  console.log('Start');
  await Promise.race([fetchData(), delay(2000)]);
  console.log('End');
}

example();
```

> [!example]- Answer
> ```text
> Start
> ReferenceError: delay is not defined
> ```
> `Start` does print first, because the arguments to `Promise.race` are evaluated after that line. Then it throws, because `delay` was never written. The original notebook cell has the same bug.
>
> With a real `delay`, the answer would be `Start`, then one second later `End`, because `race` settles as soon as the first promise does and `fetchData` is faster. `race` is the standard way to build a timeout: race the real work against a timer that rejects.

---

## 7. Await a rejection after a success

```js
async function example() {
  console.log('Start');
  const data = await fetchData();
  console.log(data);
  await Promise.reject(new Error('Error occurred'));
  console.log('End');
}

example().catch(error => console.log(error.message));
```

> [!example]- Answer
> ```text
> Start
> (one second passes)
> Data
> Error occurred
> ```
> `End` never prints. An `await` on a rejected promise behaves exactly like `throw`, so it leaves the function, and the caller's `.catch` picks it up.

---

## 8. try, catch, and a return

```js
async function example() {
  console.log('Start');
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
> Start
> (one second passes)
> Error occurred
> Finally
> ```
> `End` never runs, because the `catch` returned. `Finally` still runs, because `finally` runs on the way out however you leave.

---

## 9. try, catch, and a throw

```js
async function example() {
  console.log('Start');
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
> Start
> (one second passes)
> Error occurred
> Finally
> Another error
> ```
> The original error was swallowed and replaced. `Finally` runs before the caller sees anything. If you need both errors, pass the first as the `cause` option rather than discarding it.

---

## 10. A catch that catches nothing

```js
async function example() {
  console.log('Start');
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
> Start
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
  console.log('Start');
  fetchData()
    .then(console.log)
    .finally(() => console.log('Finally'));
  console.log('End');
}

example();
```

> [!example]- Answer
> ```text
> Start
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
  console.log('Start');
  const data = await fetchData();
  console.log(data);
  await fetchData().finally(() => console.log('Finally'));
  console.log('End');
}

example();
```

> [!example]- Answer
> ```text
> Start
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
  console.log('Start');
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
> Start
> (one second passes)
> Error occurred 2
> End
> ```
> The `1` never appears, which is the proof that the `try` block was abandoned at the `await` and the line after it never ran. Marking your log lines like this is a cheap way to find out how far execution actually got.

---

## 15. Awaiting something already resolved

```js
async function example() {
  console.log('Start');
  const data = await fetchData();
  console.log(data);
  await Promise.resolve('Resolved');
  console.log('End');
}

example();
```

> [!example]- Answer
> ```text
> Start
> (one second passes)
> Data
> End
> ```
> Compare puzzle 7, which is this exact shape with `Promise.reject` instead, where `End` never prints. The pair is worth keeping together: the only difference is whether the second promise resolved, and that decides whether the rest of the function exists.
>
> Worth knowing that `await Promise.resolve(x)` still yields to the microtask queue rather than continuing straight through. `End` runs in a later microtask, not on the same line of execution.
