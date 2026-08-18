# Promise Puzzles, Combinators

> [!tldr]
> Questions about how Promise.all, allSettled, and race behave when multiple promises settle at different times or with mixed outcomes.

Part of [[puzzles-promises]].

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
  const [data1, data2] = await Promise.all([fetchData(), fetchData()]);
  console.log(data1, data2);
  console.log('End');
}

example();
```

> [!example]- Answer
> ```text
> (one second passes, not two)
> Data Data
> End
> ```
> They run at the same time, so the total wait is the slowest one rather than the sum. Awaiting them on separate lines would take two seconds.

---

## 3. Promise.all where both reject at different times

```js
async function example() {
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
> ReferenceError: delay is not defined
> ```
> `Start` does print first, because the arguments to `Promise.race` are evaluated after that line. Then it throws, because `delay` was never written. The original notebook cell has the same bug.
>
> With a real `delay`, the answer would be `Start`, then one second later `End`, because `race` settles as soon as the first promise does and `fetchData` is faster. `race` is the standard way to build a timeout: race the real work against a timer that rejects.
