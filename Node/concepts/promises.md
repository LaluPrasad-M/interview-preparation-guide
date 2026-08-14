# Promises

> [!tldr]
> Four combinators, and one rule about errors: an `await` that rejects behaves exactly like a `throw`, so `try` and `catch` work normally.

---

## The combinators

| | Resolves when | Rejects when |
| --- | --- | --- |
| `Promise.all` | every promise resolves | the first one rejects, immediately, without waiting for the rest |
| `Promise.allSettled` | all of them finish, however they finish | never |
| `Promise.race` | the first one settles, resolved or rejected | the first one settles, if that was a rejection |
| `Promise.any` | the first one resolves | all of them reject |

`Promise.all` also accepts plain values, which it treats as already resolved:

```js
Promise.all([Promise.resolve(3), 42, slowPromise]).then(console.log);
// [3, 42, 'foo']
```

---

## all vs allSettled

```js
try {
  await Promise.all([fetchData(1000), fetchData(5000)]);
} catch (error) {
  console.log(error.message); // fires at 1000ms, not 5000ms
}
```

`Promise.all` gives up the moment anything fails. That is what you want when you need all the results, and wrong when you want to know which ones worked:

```js
const results = await Promise.allSettled([fetchData(), fetchAnotherData()]);

results.forEach((result, index) => {
  if (result.status === 'fulfilled') console.log(index, 'Data:', result.value);
  else console.log(index, 'Error:', result.reason.message);
});
```

> [!warning] allSettled never rejects
> Wrapping it in `try` and `catch` is pointless, and the `catch` block is dead code. Every outcome arrives inside the results array instead.

---

## Errors

```js
async function example() {
  try {
    const data = await fetchData();     // rejects
    console.log(data);                  // skipped
  } catch (error) {
    console.log(error.message);
    throw new Error('Another error');   // replaces the original
  } finally {
    console.log('Finally');             // runs either way
  }
  console.log('End');                   // never reached, we threw
}

example().catch(error => console.log(error.message));
```

Three things worth holding on to. `finally` runs whether you returned, threw, or fell through. Throwing inside `catch` means the caller has to handle it, so the `async` function needs a `.catch` at the call site. And a `return` inside `catch` skips the rest of the function but still runs `finally`.

---

## Not awaiting is a decision

```js
async function example() {
  console.log('Start');
  fetchData().then(console.log).finally(() => console.log('Finally'));
  console.log('End');   // prints before either of the above
}
```

Leaving off `await` means the function does not wait. Sometimes that is what you want. Usually it means an unhandled rejection later, and Node has terminated the process on those since version 15.

---

## Nested promises flatten themselves

```js
function chainedPromises() {
  return new Promise(res1 =>
    res1(new Promise(res2 =>
      res2(new Promise(res3 => setTimeout(res3, 1000, 'Data'))))));
}

console.log(await chainedPromises());  // 'Data'
```

Three promises deep, and one `await` unwraps all of it. Resolving a promise with another promise makes the outer one wait for the inner one, however many layers there are. You never get a promise of a promise back.

---

## The cooking example

> [!example]- Making a meal, as a promise chain
> Every step is a promise, and some steps are built out of smaller steps.
>
> ```js
> function washRice(value) {
>   console.log('starting washRice 1');
>   return new Promise(function (resolve) {
>     console.log('starting washRice');
>     resolve('Washed Rice');
>     console.log('After Cooking Rice');   // still runs, resolve does not return
>   });
>   console.log('ending washRice 1');      // never runs, it is after a return
> }
>
> function cookRice(value) {
>   return new Promise(function (resolve) {
>     washRice()
>       .then(boilRice)
>       .then(function (value) {
>         resolve('Rice Cooked');
>       });
>   });
> }
>
> function cookFood(value) {
>   return new Promise(function (resolve) {
>     cookRice()
>       .then(cookCurry)
>       .then(function (value) {
>         resolve('Food Cooked');
>       });
>   });
> }
>
> console.log('Wash Hands before Food');
> cookFood()
>   .then(eatFood)
>   .then(value => console.log('Wash Hands after Food'));
> console.log('END Of Process');
> ```
>
> Three lessons hide in the log order:
>
> 1. `END Of Process` prints almost immediately, long before the food is cooked. The chain was only started, not waited for.
> 2. `resolve()` is not `return`. The line after it still runs, which is why `After Cooking Rice` appears.
> 3. Code after a `return` never runs, so `ending washRice 1` prints never.
>
> The nesting also shows why `async` and `await` won. The same logic written with `await` is six flat lines with no `new Promise` at all.
