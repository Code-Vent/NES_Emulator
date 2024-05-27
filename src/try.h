#pragma once
#include<stdint.h>
#include<assert.h>

struct TimerParams {

};

struct Tryable {
	virtual void Try() = 0;
};

class Timer {
public:
	Timer(Tryable*, TimerParams&);
	void start();
	void operator()();
	operator bool();
	void lock();
private:
	void init(TimerParams&);
	void reset() const;
	Tryable* todo;
};


inline Timer::Timer(Tryable* T, TimerParams& t)
{
	todo = T;
	init(t);
}

inline void Timer::start()
{
}

inline void Timer::operator()()
{
	assert(todo != nullptr);
	todo->Try();
	reset();
}

inline Timer::operator bool()
{
}

inline void Timer::lock()
{
}

inline void Timer::init(TimerParams&)
{
}

inline void Timer::reset() const
{
}
